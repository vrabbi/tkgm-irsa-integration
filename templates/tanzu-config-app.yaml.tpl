apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: ${cluster_name}-tkg-pkgr
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
        config/pkgr.yaml: |
          apiVersion: packaging.carvel.dev/v1alpha1
          kind: PackageRepository
          metadata:
            annotations:
              kapp.k14s.io/change-group: "setup"
            name: tanzu-standard
            namespace: tkg-system
          spec:
            fetch:
              imgpkgBundle:
                image: projects.registry.vmware.com/tkg/packages/standard/repo:v2.1.0
        config/packages-namespace.yaml: |
          apiVersion: v1
          kind: Namespace
          metadata:
            annotations:
              kapp.k14s.io/change-group: "setup"
            name: tkg-packages
        config/sa.yaml: |
          apiVersion: v1
          kind: ServiceAccount
          metadata:
            annotations:
              kapp.k14s.io/change-group: "rbac"
              kapp.k14s.io/change-rule: "upsert after upserting setup"
              tkg.tanzu.vmware.com/tanzu-package: cert-manager-tkg-packages
            name: cert-manager-tkg-packages-sa
            namespace: tkg-packages
        config/cluster-role.yaml: |
          apiVersion: rbac.authorization.k8s.io/v1
          kind: ClusterRole
          metadata:
            annotations:
              kapp.k14s.io/change-group: "rbac"
              kapp.k14s.io/change-rule: "upsert after upserting setup"
              tkg.tanzu.vmware.com/tanzu-package: cert-manager-tkg-packages
            name: cert-manager-tkg-packages-cluster-role
          rules:
          - apiGroups:
            - '*'
            resources:
            - '*'
            verbs:
            - '*'
        config/cluster-role-binding.yaml: |
          apiVersion: rbac.authorization.k8s.io/v1
          kind: ClusterRoleBinding
          metadata:
            annotations:
              kapp.k14s.io/change-group: "rbac"
              kapp.k14s.io/change-rule: "upsert after upserting setup"
              tkg.tanzu.vmware.com/tanzu-package: cert-manager-tkg-packages
            name: cert-manager-tkg-packages-cluster-rolebinding
          roleRef:
            apiGroup: rbac.authorization.k8s.io
            kind: ClusterRole
            name: cert-manager-tkg-packages-cluster-role
          subjects:
          - kind: ServiceAccount
            name: cert-manager-tkg-packages-sa
            namespace: tkg-packages
        config/cert-manager.yaml: |
          apiVersion: packaging.carvel.dev/v1alpha1
          kind: PackageInstall
          metadata:
            annotations:
              kapp.k14s.io/change-group: "install"
              kapp.k14s.io/change-rule: "upsert after upserting rbac"
              tkg.tanzu.vmware.com/tanzu-package-ClusterRole: cert-manager-tkg-packages-cluster-role
              tkg.tanzu.vmware.com/tanzu-package-ClusterRoleBinding: cert-manager-tkg-packages-cluster-rolebinding
              tkg.tanzu.vmware.com/tanzu-package-ServiceAccount: cert-manager-tkg-packages-sa
            name: cert-manager
            namespace: tkg-packages
          spec:
            packageRef:
              refName: cert-manager.tanzu.vmware.com
              versionSelection:
                constraints: 1.7.2+vmware.1-tkg.1
            serviceAccountName: cert-manager-tkg-packages-sa

  syncPeriod: 5m0s
  template:
  - ytt:
      ignoreUnknownComments: true
      paths:
      - config/
