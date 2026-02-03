---
description: This section provides instructions on troubleshooting common issues that may arise during the deployment of Intel TDX-protected, attested applications in a Kubernetes cluster.
keywords: enabling guide, Intel TDX, Trust Domain Extension, Confidential Computing, Confidential Containers, troubleshooting
---
<!---
Copyright (C) 2024 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Troubleshooting

This section provides instructions on troubleshooting common issues that may arise during the deployment of workload applications in a Kubernetes cluster, protected with Intel TDX and verified using attestation.

If the below guide does not resolve your issue, refer to [Confidential Containers Troubleshooting Guide](https://confidentialcontainers.org/docs/troubleshooting/) for more information.


## Pods Failed to Start

This section provides guidance on how to resolve the issue when pods fail to start due to missing parent snapshot.
Such a problem might occur when containerd's plugin (Nydus Snapshotter) failed to clean the images correctly.

To see if your pod is affected by this issue, run the following command:

``` { .bash }
kubectl describe pod <pod name>
```

Below kind of errors with containerd's plugin (Nydus Snapshotter) will be indicated by the following error message:

``` { .text }
failed to create containerd container: create snapshot: missing parent \"k8s.io/2/sha256:961e...\" bucket: not found
```
``` { .text }
failed to create containerd container: error unpacking image: failed to extract layer sha256:<hash1>: failed to get reader from content store: content digest sha256:<hash2>: not found
```

``` { .text }
Error: failed to create containerd container: error unpacking image: failed to extract layer sha256:<SHA>: failed to get reader from content store: content digest sha256:<SHA>: not found
```

To resolve the issue, try the following procedure:

1. Remove your pod:

    ``` { .bash }
    kubectl delete pod <pod name>
    ```

2. Clear the Kubernetes images cache:

    ``` { .bash }
    # Remove cache for the image causing problems
    sudo crictl rmi <image name with tag>
    # Remove all unused cached images
    sudo crictl rmi --prune
    ```

3. Remove all data collected by containerd's plugin (Nydus Snapshotter):

    ``` { .bash }
    sudo ctr -n k8s.io images rm $(sudo ctr -n k8s.io images ls -q)
    sudo ctr -n k8s.io content rm $(sudo ctr -n k8s.io content ls -q)
    sudo ctr -n k8s.io snapshots rm $(sudo ctr -n k8s.io snapshots --snapshotter nydus ls | awk 'NR>1 {print $1}')
    ```

4. Disable optimized disk usage enabled in containerd:

    ``` { .bash }
    sudo sed -i 's/discard_unpacked_layers = true/discard_unpacked_layers = false/' /etc/containerd/config.toml
    sudo grep discard_unpacked_layers /etc/containerd/config.toml
    sudo systemctl restart containerd
    ```

5. Re-deploy Confidential Containers-related runtime classes using simplified commands based on the [install Confidential Containers instruction](../02/infrastructure_setup.md#install-confidential-containers):

    ``` { .bash }
    helm uninstall coco --namespace coco-system
    helm install coco oci://ghcr.io/confidential-containers/charts/confidential-containers \
       --namespace coco-system \
       --create-namespace
    ```

6. Re-deploy your pod:

    ``` { .bash }
    kubectl apply -f <pod yaml>
    ```

## Attestation Failure

This section pinpoints the most common reasons for attestation failure and provides guidance on how to resolve them.
An attestation failure is indicated by the fact that pod is in `Init:Error` state and `ATTESTATION FAILED` message is present in the logs of the pod.

!!! note
    The example outputs presented in the following might differ from your output, because of different names of the pods/deployments or different IP addresses.

To identify if you encounter an attestation failure, follow the steps below:

- Retrieve the status of the `nginx-td-attestation` pod:

    ``` { .bash }
    kubectl get pods
    ```

    Sample output with nginx-td-attestation pod is in `Init:Error` state:

    ``` { .text }
    NAME                   READY   STATUS    RESTARTS   AGE
    nginx-td-attestation   0/1     Init:Error   0          1m
    ```

- Get the logs of the `init-attestation` container in the `nginx-td-attestation` pod:

    ``` { .bash }
    kubectl logs pod/nginx-td-attestation -c init-attestation
    ```

    Sample output indicating the `ATTESTATION FAILED` message:

    ``` { .text }
    NAME                   READY   STATUS    RESTARTS   AGE
    starting
    (...)
    ATTESTATION FAILED
    ```

In case of attestation failure, follow the steps below to troubleshoot the issue:

- If you have configured KBS with Intel® Trust Authority, check that API key is correct and KBS was deployed with this value:

    ``` { .bash }
    kubectl describe configmap kbs-config -n coco-tenant | grep -i api_key
    ```

    Expected output:

    ``` { .text }
    api_key = "<YOUR_ITA_API_KEY>"
    ```

- Check if the KBS pod is running and accessible:

    ``` { .bash }
    echo $(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'):$(kubectl get svc kbs -n coco-tenant -o jsonpath='{.spec.ports[0].nodePort}')
    ```

    Expected output:

    ``` { .text }
    <protocol>://<address>:<port>
    ```

- Check KBS logs for any errors:

    ``` { .bash }
    kubectl logs deploy/kbs -n coco-tenant
    ```

    An `HTTP 400 Bad Request` error might suggest that platform is not registered correctly.
    Refer to the [platform registration](../../../intel-tdx-enabling-guide/02/infrastructure_setup/#platform-registration) section of the Intel TDX Enabling Guide for details.

- Check for errors in Intel PCCS service:

    ``` { .bash }
    systemctl status pccs
    ```

    Use the following command to get more logs:

    ``` { .bash }
    sudo journalctl -u pccs
    ```

- Check for errors in Intel TDX Quote Generation Service:

    ``` { .bash }
    systemctl status qgsd
    ```

    Use the following command to get more logs:

    ``` { .bash }
    sudo journalctl -u qgsd
    ```

    The following error occurs if the platform is not registered correctly.

    ``` { .text }
    [QPL] No certificate data for this platform.
    ```

    Refer to the [platform registration](../../../intel-tdx-enabling-guide/02/infrastructure_setup/#platform-registration) section of the Intel TDX Enabling Guide for details.
