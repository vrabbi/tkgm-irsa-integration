data "template_file" "discovery_json" {
  template = file("${path.module}/templates/discovery_json.tpl")
  vars = {
    region = var.aws_region
    bucket = aws_s3_bucket.tkg_irsa_bucket.id
  }
}

resource "aws_s3_bucket" "tkg_irsa_bucket" {
  bucket              = "${var.cluster_name}-irsa-bucket"
  force_destroy       = "false"
  object_lock_enabled = "false"

}

resource "aws_s3_object" "discovery_json" {
  bucket       = aws_s3_bucket.tkg_irsa_bucket.id
  key          = ".well-known/openid-configuration"
  content      = data.template_file.discovery_json.rendered
  acl          = "public-read"
  content_type = "application/json"
}

data "tls_certificate" "bucket" {
  url = "https://s3-${var.aws_region}.amazonaws.com/${aws_s3_bucket.tkg_irsa_bucket.id}"
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [join("", data.tls_certificate.bucket.*.certificates.0.sha1_fingerprint)]
  url             = "https://s3-${var.aws_region}.amazonaws.com/${aws_s3_bucket.tkg_irsa_bucket.id}"
}

resource "aws_iam_role" "tkg_irsa_role" {
  for_each = { for config in var.iam_role_configs : config.name => config }
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc_provider.arn
      }
      Condition = {
        StringLike = {
          "${aws_iam_openid_connect_provider.oidc_provider.url}:aud" : "sts.amazonaws.com",
          "${aws_iam_openid_connect_provider.oidc_provider.url}:sub" : [
            "system:serviceaccount:${each.value.ns_sa_string}"
          ]
        }
      }
    }]
    Version = "2012-10-17"
  })
  managed_policy_arns  = [each.value.managed_policy_arn]
  max_session_duration = "3600"
  name                 = each.value.name
  path                 = "/"

}

# Get The SA Signing Key From The MGMT Cluster
data "kubernetes_secret" "sa_rsa_pub" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.mgmt
  metadata {
    name      = "${var.cluster_name}-sa"
    namespace = "default"
  }
}

# Create Base JWKS Data Structure From The SA Signing Key
data "jwks_from_pem" "sa_signing_key" {
  count = var.cluster_created ? 1 : 0
  pem   = data.kubernetes_secret.sa_rsa_pub[0].data["tls.crt"]
}

# Get The Default Service Account From The Workload Cluster
data "kubernetes_service_account" "default" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  metadata {
    name      = "default"
    namespace = "default"
  }
}

# Get The Default Service Accounts Password
data "kubernetes_secret" "default" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  metadata {
    name      = data.kubernetes_service_account.default[0].default_secret_name
    namespace = "default"
  }
}

# Extract the Key ID in the way kubernetes represents it from the SAs JWT Token Headers
locals {
  token_headers = try(split(".", data.kubernetes_secret.default[0].data.token)[0], "")
  token_fixed   = "${local.token_headers}=="
  kid           = try(jsondecode(base64decode(local.token_fixed)).kid, null)
  alg           = try(jsondecode(base64decode(local.token_fixed)).alg, null)
  jwks_data     = try(jsondecode(data.jwks_from_pem.sa_signing_key[0].jwks), null)
}


data "template_file" "keys_json" {
  count    = var.cluster_created ? 1 : 0
  template = file("${path.module}/templates/keys_json.tpl")
  vars = {
    kid = local.kid
    kty = local.jwks_data.kty
    e   = local.jwks_data.e
    n   = local.jwks_data.n
    use = "sig"
    alg = local.alg
  }
}

resource "aws_s3_object" "keys_json" {
  count        = var.cluster_created ? 1 : 0
  bucket       = aws_s3_bucket.tkg_irsa_bucket.id
  key          = "keys.json"
  content      = data.template_file.keys_json[0].rendered
  acl          = "public-read"
  content_type = "application/json"
}








resource "kubernetes_service_account" "pod_identity_webhook" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  metadata {
    name      = "pod-identity-webhook"
    namespace = "kube-system"
  }
}

resource "kubernetes_role" "pod_identity_webhook" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  metadata {
    name      = "pod-identity-webhook"
    namespace = "kube-system"
  }

  rule {
    verbs      = ["create"]
    api_groups = [""]
    resources  = ["secrets"]
  }

  rule {
    verbs          = ["get", "update", "patch"]
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["pod-identity-webhook"]
  }
}

resource "kubernetes_role_binding" "pod_identity_webhook" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  metadata {
    name      = "pod-identity-webhook"
    namespace = "kube-system"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "pod-identity-webhook"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "pod-identity-webhook"
  }
}

resource "kubernetes_cluster_role" "pod_identity_webhook" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  metadata {
    name = "pod-identity-webhook"
  }

  rule {
    verbs      = ["get", "watch", "list"]
    api_groups = [""]
    resources  = ["serviceaccounts"]
  }

  rule {
    verbs      = ["create", "get", "list", "watch"]
    api_groups = ["certificates.k8s.io"]
    resources  = ["certificatesigningrequests"]
  }
}

resource "kubernetes_cluster_role_binding" "pod_identity_webhook" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  metadata {
    name = "pod-identity-webhook"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "pod-identity-webhook"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "pod-identity-webhook"
  }
}

resource "kubernetes_deployment" "pod_identity_webhook" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  metadata {
    name      = "pod-identity-webhook"
    namespace = "kube-system"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "pod-identity-webhook"
      }
    }

    template {
      metadata {
        labels = {
          app = "pod-identity-webhook"
        }
      }

      spec {
        volume {
          name = "cert"

          secret {
            secret_name = "pod-identity-webhook-cert"
          }
        }

        container {
          name    = "pod-identity-webhook"
          image   = "amazon/amazon-eks-pod-identity-webhook:latest"
          command = ["/webhook", "--in-cluster=false", "--namespace=kube-system", "--service-name=pod-identity-webhook", "--annotation-prefix=eks.amazonaws.com", "--token-audience=sts.amazonaws.com", "--logtostderr"]

          volume_mount {
            name       = "cert"
            read_only  = true
            mount_path = "/etc/webhook/certs"
          }

          image_pull_policy = "Always"
        }

        service_account_name = "pod-identity-webhook"
      }
    }
  }
}

resource "kubernetes_manifest" "clusterissuer_selfsigned" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "selfsigned"
    }
    "spec" = {
      "selfSigned" = {}
    }
  }
}

resource "kubernetes_manifest" "certificate_kube_system_pod_identity_webhook" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "pod-identity-webhook"
      "namespace" = "kube-system"
    }
    "spec" = {
      "commonName" = "pod-identity-webhook.kube-system.svc"
      "dnsNames" = [
        "pod-identity-webhook",
        "pod-identity-webhook.kube-system",
        "pod-identity-webhook.kube-system.svc",
        "pod-identity-webhook.kube-system.svc.local",
      ]
      "duration" = "2160h0m0s"
      "isCA"     = true
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "selfsigned"
      }
      "renewBefore" = "360h0m0s"
      "secretName"  = "pod-identity-webhook-cert"
    }
  }
}

resource "kubernetes_mutating_webhook_configuration" "pod_identity_webhook" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  metadata {
    name = "pod-identity-webhook"

    annotations = {
      "cert-manager.io/inject-ca-from" = "kube-system/pod-identity-webhook"
    }
  }

  webhook {
    name = "pod-identity-webhook.amazonaws.com"

    client_config {
      service {
        namespace = "kube-system"
        name      = "pod-identity-webhook"
        path      = "/mutate"
      }
    }

    rule {
      operations   = ["CREATE"]
      api_groups   = [""]
      api_versions = ["v1"]
      resources    = ["pods"]
    }

    failure_policy            = "Ignore"
    side_effects              = "None"
    admission_review_versions = ["v1beta1"]
  }
  lifecycle {
    ignore_changes = [
      webhook[0].client_config[0].ca_bundle
    ]
  }
}

resource "kubernetes_service" "pod_identity_webhook" {
  count    = var.cluster_created ? 1 : 0
  provider = kubernetes.workload
  metadata {
    name      = "pod-identity-webhook"
    namespace = "kube-system"

    annotations = {
      "prometheus.io/port" = "443"

      "prometheus.io/scheme" = "https"

      "prometheus.io/scrape" = "true"
    }
  }

  spec {
    port {
      port        = 443
      target_port = "443"
    }

    selector = {
      app = "pod-identity-webhook"
    }
  }
}
