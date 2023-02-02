apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: ${cluster_name}-irsa-webhook
  namespace: ${namespace}
spec:
  noopDelete: true
  cluster:
    kubeconfigSecretRef:
      key: value
      name: ${cluster_name}-kubeconfig
  deploy:
  - kapp:
      rawOptions:
      - --wait-timeout=30s
      - --kube-api-qps=20
      - --kube-api-burst=30
  fetch:
  - inline:
      paths:
        config/sa.yaml: |
          apiVersion: v1
          kind: ServiceAccount
          metadata:
            name: pod-identity-webhook
            namespace: kube-system
        config/role.yaml: |
          apiVersion: rbac.authorization.k8s.io/v1
          kind: Role
          metadata:
            name: pod-identity-webhook
            namespace: kube-system
          rules:
          - apiGroups:
            - ""
            resources:
            - secrets
            verbs:
            - create
          - apiGroups:
            - ""
            resources:
            - secrets
            verbs:
            - get
            - update
            - patch
            resourceNames:
            - "pod-identity-webhook"
        config/role-binding.yaml: |
          apiVersion: rbac.authorization.k8s.io/v1
          kind: RoleBinding
          metadata:
            name: pod-identity-webhook
            namespace: kube-system
          roleRef:
            apiGroup: rbac.authorization.k8s.io
            kind: Role
            name: pod-identity-webhook
          subjects:
          - kind: ServiceAccount
            name: pod-identity-webhook
            namespace: kube-system
        config/cluster-role.yaml: |
          apiVersion: rbac.authorization.k8s.io/v1
          kind: ClusterRole
          metadata:
            name: pod-identity-webhook
          rules:
          - apiGroups:
            - ""
            resources:
            - serviceaccounts
            verbs:
            - get
            - watch
            - list
          - apiGroups:
            - certificates.k8s.io
            resources:
            - certificatesigningrequests
            verbs:
            - create
            - get
            - list
            - watch
        config/cluster-role-binding.yaml: |
          apiVersion: rbac.authorization.k8s.io/v1
          kind: ClusterRoleBinding
          metadata:
            name: pod-identity-webhook
          roleRef:
            apiGroup: rbac.authorization.k8s.io
            kind: ClusterRole
            name: pod-identity-webhook
          subjects:
          - kind: ServiceAccount
            name: pod-identity-webhook
            namespace: kube-system
        config/deployment.yaml: |
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: pod-identity-webhook
            namespace: kube-system
          spec:
            replicas: 1
            selector:
              matchLabels:
                app: pod-identity-webhook
            template:
              metadata:
                labels:
                  app: pod-identity-webhook
              spec:
                serviceAccountName: pod-identity-webhook
                containers:
                - name: pod-identity-webhook
                  image: amazon/amazon-eks-pod-identity-webhook:latest
                  imagePullPolicy: Always
                  command:
                  - /webhook
                  - --in-cluster=false
                  - --namespace=kube-system
                  - --service-name=pod-identity-webhook
                  - --annotation-prefix=eks.amazonaws.com
                  - --token-audience=sts.amazonaws.com
                  - --logtostderr
                  volumeMounts:
                  - name: cert
                    mountPath: "/etc/webhook/certs"
                    readOnly: true
                volumes:
                - name: cert
                  secret:
                    secretName: pod-identity-webhook-cert
        config/cluster-issuer.yaml: |
          apiVersion: cert-manager.io/v1
          kind: ClusterIssuer
          metadata:
            name: selfsigned
          spec:
            selfSigned: {}
        config/cert.yaml: |
          apiVersion: cert-manager.io/v1
          kind: Certificate
          metadata:
            name: pod-identity-webhook
            namespace: kube-system
          spec:
            secretName: pod-identity-webhook-cert
            commonName: "pod-identity-webhook.kube-system.svc"
            dnsNames:
            - "pod-identity-webhook"
            - "pod-identity-webhook.kube-system"
            - "pod-identity-webhook.kube-system.svc"
            - "pod-identity-webhook.kube-system.svc.local"
            isCA: true
            duration: 2160h
            renewBefore: 360h
            issuerRef:
              name: selfsigned
              kind: ClusterIssuer
        config/webhook.yaml: |
          apiVersion: admissionregistration.k8s.io/v1
          kind: MutatingWebhookConfiguration
          metadata:
            name: pod-identity-webhook
            namespace: kube-system
            annotations:
              cert-manager.io/inject-ca-from: kube-system/pod-identity-webhook
          webhooks:
          - name: pod-identity-webhook.amazonaws.com
            failurePolicy: Ignore
            clientConfig:
              service:
                name: pod-identity-webhook
                namespace: kube-system
                path: "/mutate"
            rules:
            - operations: [ "CREATE" ]
              apiGroups: [""]
              apiVersions: ["v1"]
              resources: ["pods"]
            sideEffects: None
            admissionReviewVersions: ["v1beta1"]
        config/service.yaml: |
          apiVersion: v1
          kind: Service
          metadata:
            name: pod-identity-webhook
            namespace: kube-system
            annotations:
              prometheus.io/port: "443"
              prometheus.io/scheme: "https"
              prometheus.io/scrape: "true"
          spec:
            ports:
            - port: 443
              targetPort: 443
            selector:
              app: pod-identity-webhook
  syncPeriod: 5m0s
  template:
  - ytt:
      ignoreUnknownComments: true
      paths:
      - config/
