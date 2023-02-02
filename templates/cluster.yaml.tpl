---
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  annotations:
    osInfo: ${os_name},${os_version},amd64
    tkg/plan: dev
  labels:
    tkg.tanzu.vmware.com/cluster-name: ${cluster_name}
  name: ${cluster_name}
  namespace: ${namespace}
spec:
  clusterNetwork:
    pods:
      cidrBlocks:
      - 100.96.0.0/11
    services:
      cidrBlocks:
      - 100.64.0.0/13
  topology:
    class: ${cluster_class_name}
    controlPlane:
      metadata:
        annotations:
          run.tanzu.vmware.com/resolve-os-image: image-type=ova,os-name=${os_name}
      replicas: ${cp_node_count}
    variables:
    - name: cni
      value: ${cni}
    - name: auditLogging
      value:
        enabled: ${auditLogging}
    - name: aviAPIServerHAProvider
      value: true
    - name: vcenter
      value:
        cloneMode: ${cloneMode}
        datacenter: ${datacenter}
        datastore: ${datastore}
        folder: ${folder}
        network: ${network}
        resourcePool: ${resourcePool}
        server: ${server}
        storagePolicyID: ${storagePolicyID}
        template: ${template}
    - name: apiServerExtraArgs
      value:
        api-audiences: "sts.amazonaws.com"
        service-account-issuer: "https://s3-${aws_region}.amazonaws.com/${cluster_name}-irsa-bucket"
    - name: user
      value:
        sshAuthorizedKeys:
        - ${ssh_public_key}
    - name: controlPlane
      value:
        machine:
          diskGiB: ${controlPlaneDiskGB}
          memoryMiB: ${controlPlaneMemoryMB}
          numCPUs: ${controlPlaneNumCPUs}
        network:
          nameservers:
            - ${nameserver}
          searchDomains:
            - ${searchDomain}
        nodeLabels: []
    - name: worker
      value:
        machine:
          diskGiB: ${workerDiskGB}
          memoryMiB: ${workerMemoryMB}
          numCPUs: ${workerNumCPUs}
        network:
          nameservers:
            - ${nameserver}
          searchDomains:
            - ${searchDomain}
    version: ${k8s_version}
    workers:
      machineDeployments:
      - class: tkg-worker
        metadata:
          annotations:
            run.tanzu.vmware.com/resolve-os-image: image-type=ova,os-name=${os_name}
        name: md-0
        replicas: ${worker_node_count}
