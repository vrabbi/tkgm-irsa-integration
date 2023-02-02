---
apiVersion: v1
kind: Secret
metadata:
  name: ${cluster_name}
  namespace: ${namespace}
data:
  password: ${vsphere_password}
  username: ${vsphere_username}
