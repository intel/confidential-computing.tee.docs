---
description: This page provides instructions on how to set up the infrastructure required to use the Confidential Containers project to start an Intel TDX-protected application within a Kubernetes environment.
keywords: enabling guide, Intel TDX, Trust Domain Extension, Confidential Computing, Confidential Containers, infrastructure setup, Intel DCAP, Kata Containers, Nydus Snapshotter, remote attestation
---
<!---
Copyright (C) 2024 Intel Corporation
SPDX-License-Identifier: CC-BY-4.0
-->

# Infrastructure Setup

On this page, we will set up the infrastructure required to run Confidential Containers with Intel® Trust Domain Extensions (Intel® TDX) in a Kubernetes environment.
This chapter is intended for the administrator of the Kubernetes cluster.

In detail, we cover the following tasks:

1. [Prerequisites](#prerequisites)

    We introduce the necessary prerequisites that we assume for the infrastructure setup.

2. [Install Confidential Containers](#install-confidential-containers)

    We explore how to deploy Kata Containers, a lightweight container runtime, to allow running containers as lightweight VMs, or Intel TDX-protected VMs (i.e., TDs).
    We use Helm charts to manage the Confidential Containers Runtime on a Kubernetes cluster.

3. [Install Attestation Components](#install-attestation-components)

    We discuss how to deploy attestation components that ensure that the pods are running the expected workloads, that the pods are protected by Intel TDX on a genuine Intel platform, that the platform is patched to a certain level, and that certain other security relevant information is as expected.
    As an example, we show how to integrate different attestation services into the Confidential Containers Key Broker Service (KBS): Intel® Trust Authority and an Intel® DCAP-based attestation service.

4. [Cleanup](#cleanup)

    We provide commands to remove the deployed components step by step from the Kubernetes cluster.


## Prerequisites

This section describes the prerequisites that we assume for the following steps regarding installed software and optionally access to an Intel Trust Authority API Key.


### Installed Software

Ensure that your infrastructure meets the following requirements:

- [Kubernetes](https://kubernetes.io/),
- Kubernetes cluster with at least one node - serving as master and worker node,
- [containerd](https://containerd.io/) 1.7.29 or newer,
- [Helm](https://helm.sh/docs/intro/install) - 3.8 or newer,
- Worker nodes configured on [registered](../../../intel-tdx-enabling-guide/02/infrastructure_setup/#platform-registration) Intel platforms with Intel TDX Module.

!!! Note "Intel TDX Enabling"
    The registration of Intel platform referred above does not yet fully cover Ubuntu 24.04.
    For additional details, refer to [Canonical's guide](https://github.com/canonical/tdx/blob/3.3/README.md) to configure Intel TDX.
    Especially, the [remote attestation chapter](https://github.com/canonical/tdx/blob/3.3/README.md#setup-remote-attestation) provides details about the configuration of remote attestation.


### Intel Trust Authority API Key

!!! Note
    This is optional step only if you want to use Intel Trust Authority as an attestation service.

To enable remote attestation of applications as explained in the following chapter, you need to have access to an Intel Trust Authority API Key (later referred to as `ITA_API_KEY`).

If you do not yet have such a key, you will find instructions on the [Intel Trust Authority website](https://www.intel.com/content/www/us/en/security/trust-authority.html).
In particular, you will find the option to start a free trial.


## Install Confidential Containers

In this section, we will deploy all required components to run containers as lightweight Intel TDX-protected VMs (i.e., TDs).
In particular, we use Helm charts to deploy and manage the Confidential Containers Runtime on a Kubernetes clusters.

For more details, see the complete instruction in the [CoCo Quick Start](https://github.com/confidential-containers/confidential-containers/blob/main/quickstart.md#installation) and [CoCo Getting Started](https://confidentialcontainers.org/docs/getting-started/).


### Preparation

1. Ensure your cluster's node is labeled:

    ``` { .bash }
    kubectl label node $(kubectl get nodes | awk 'NR!=1 { print $1 }') \
      node.kubernetes.io/worker=
    ```

2. Set the environment variable `HELM_CHARTS_RELEASE_VERSION` to the version of the Helm chart that should be used for the Confidential Containers deployment.
    All available versions can be found [on the corresponding GitHub page](https://github.com/confidential-containers/charts/releases).

    !!! Note
        This guide was tested with the version `v0.18.0`.

    ``` { .bash }
    export HELM_CHARTS_RELEASE_VERSION=0.18.0
    ```

3. Set the environment variable `HELM_COCO_CHART_NAME` to give a name to the Confidential Containers deployment:

    ``` { .bash }
    export HELM_COCO_CHART_NAME=coco
    ```


### Installation

1. Create a [Helm values file](https://helm.sh/docs/chart_template_guide/values_files/) (`tdx-values.yaml`) with the following content to enable all runtimes and shims relevant for Intel TDX:

     ``` { .yaml }
     kata-as-coco-runtime:
       shims:
         disableAll: true
         qemu-tdx:
           enabled: true
         qemu-nvidia-gpu-tdx:
           enabled: true
         qemu-dev:
           enabled: true
       defaultShim:
         amd64: qemu-tdx
     ```

2. Install the CoCo runtime using a Helm chart with the created values file:

    ``` { .bash }
    helm install ${HELM_COCO_CHART_NAME} oci://ghcr.io/confidential-containers/charts/confidential-containers \
      --version ${HELM_CHARTS_RELEASE_VERSION} \
      -f tdx-values.yaml \
      --namespace coco-system \
      --create-namespace
    ```

    !!! Note
        If your network requires the usage of a proxy, you have to configure it in one of two ways:

        1. Add the following to your Helm values file (`tdx-values.yaml`):
            ``` { .yaml }
            kata-as-coco-runtime:
              shims:
                qemu-tdx:
                  agent:
                    httpsProxy: "${HTTPS_PROXY}"
                    noProxy: "${NO_PROXY}"
            ```
        2. Specify an overwrite by adding the following line to the above `helm install` command:

            ``` { .bash }
            --set kata-as-coco-runtime.shims.qemu-tdx.agent.httpsProxy="${HTTPS_PROXY}"
            --set kata-as-coco-runtime.shims.qemu-tdx.agent.noProxy="${NO_PROXY}"
            ```
        `HTTPS_PROXY` and `NO_PROXY` environment variables should be set according to the requirements of the machine where the Kubernetes cluster is deployed.

3. Wait until all pods are ready, which can be checked with the following command:

    ``` { .bash }
    kubectl -n coco-system wait --for=condition=Ready pods --all --timeout=5m
    ```

    Expected output:

    ``` { .text }
    pod/kata-as-coco-runtime-75gbh condition met
    ```

4. Check that the Confidential Containers runtime classes exist:

    ``` { .bash }
    kubectl get runtimeclass
    ```

    Expected output:

    ``` { .text }
    NAME                            HANDLER                         AGE
    kata-qemu-coco-dev              kata-qemu-coco-dev              19s
    kata-qemu-coco-dev-runtime-rs   kata-qemu-coco-dev-runtime-rs   19s
    kata-qemu-nvidia-gpu-tdx        kata-qemu-nvidia-gpu-tdx        19s
    kata-qemu-tdx                   kata-qemu-tdx                   19s
    ```


### Customization

Based on your environment, you might want to customize the Confidential Containers installation, e.g., specify which runtimes to enable, configure shims, and set default runtimes.
This can be done in following ways:

1. Provide a Helm values file to the `helm install` command, which was used in the instructions above.
2. Specify value overrides in the `helm install` command.

In the following sub-sections, we provide more details on these options, which also can be combined.
Value overrides take precedence over the values in the values file.

!!! Notes

    - **Node Selectors**: When setting node selectors with dots in the key, escape them, `node-role\.kubernetes\.io/worker`,
    - **Architecture**: The default architecture is `x86_64`.
      Other architectures must be explicitly specified,
    - **Comma Escaping**: When using `--set` with values containing commas, escape them, i.e. use `\,`.

#### Configuration via Helm values file

For complex configurations, it is recommended to create a Helm values file and pass it `helm install` using the `-f` option.

To download latest available configuration options for the chart, use below command:

``` { .bash }
helm show values oci://ghcr.io/confidential-containers/charts/confidential-containers > values.yaml
```

The Confidential Container project provides one file containing [multiple examples for Helm values files](https://github.com/confidential-containers/charts/blob/main/examples-custom-values.yaml).

#### Configuration via value overrides

For ad-hoc configurations, it is recommended use value overrides in `helm install` using the `--set` option.

For example, to only enable the Kata Containers runtime with Intel TDX support and disable all other runtimes, you can use the following value overrides:

``` { .bash }
--set kata-as-coco-runtime.shims.disableAll=true \
--set kata-as-coco-runtime.shims.qemu-tdx.enabled=true \
--set kata-as-coco-runtime.shims.qemu-nvidia-gpu-tdx.enabled=true \
--set kata-as-coco-runtime.defaultShim.amd64=qemu-tdx
```

More information about available configuration options can be found on the [Customization page](https://confidentialcontainers.org/docs/getting-started/installation/advanced_configuration/) of the Confidential Containers documentation.


## Install Attestation Components

In this section, we explore how to deploy attestation components that ensure that the pods are running the expected workloads, that the pods are protected by Intel TDX on a genuine Intel platform, that the platform is patched to a certain level, and that certain other security relevant information is as expected.

As an example, we show how to integrate different attestation services into Trustee, specifically:

- [Intel® Trust Authority](https://www.intel.com/content/www/us/en/security/trust-authority.html)
- [Intel® DCAP-based attestation service](https://github.com/intel/confidential-computing.tee.dcap)

Steps:

1. Clone the Confidential Containers Trustee repository using the following command:

    !!! Note
        This guide was tested with the version `v0.17.0`, but newer [versions](https://github.com/confidential-containers/trustee/releases) might be available.

    ``` { .bash }
    git clone -b v0.17.0 https://github.com/confidential-containers/trustee
    cd trustee/kbs/config/kubernetes/
    ```

2. If you are behind proxy, update Trustee deployment configuration:

    === ":gear: no proxy"

        No additional steps needed.

    === ":gear: with proxy"

        Set the following environmental variable according to requirements of the machine where the Kubernetes cluster is deployed:

        - `https_proxy`: value to your proxy URL.

        Run below command to apply proxy settings to Trustee deployment:

        ``` { .bash }
        sed -i "s|^\(\s*\)volumes:|\1  env:\n\1    - name: https_proxy\n\1      value: \"$https_proxy\"\n\1volumes:|" base/deployment.yaml
        ```

3. Configure Trustee according to the used attestation service variant:

    === ":gear: Intel Trust Authority"

        To configure Trustee to use Intel Trust Authority as an attestation service, set the environment variable `DEPLOYMENT_DIR` as follows:

        ``` { .bash }
        export DEPLOYMENT_DIR=ita
        ```

        Set your Intel Trust Authority API Key in Trustee configuration:

        ``` { .bash }
        sed -i 's/api_key =.*/api_key = "'${ITA_API_KEY}'"/g' $DEPLOYMENT_DIR/kbs-config.toml
        ```

    === ":gear: Intel DCAP"

        To configure the Trustee to use Intel DCAP as an attestation service, set the environment variable `DEPLOYMENT_DIR` as follows:

        ``` { .bash }
        export DEPLOYMENT_DIR=custom_pccs
        ```

4. Update your secret key that is required during deployment:

    ``` { .bash }
    echo "This is my super secret" > overlays/key.bin
    ```

5. Deploy Trustee:

    ``` { .bash }
    ./deploy-kbs.sh
    ```

    Validate whether Trustee pod is running:

    ``` { .bash }
    kubectl get pods -n coco-tenant
    ```

    Expected output:

    ``` { .bash }
    NAME                   READY   STATUS    RESTARTS   AGE
    kbs-5f4696986b-64ljx   1/1     Running   0          12s
    ```

6. Retrieve `KBS_ADDRESS` for future use in pod's yaml file:

    ``` { .bash }
    export KBS_ADDRESS=http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'):$(kubectl get svc kbs -n coco-tenant -o jsonpath='{.spec.ports[0].nodePort}')
    echo $KBS_ADDRESS
    ```

    Expected output:

    ``` { .text }
    <protocol>://<address>:<port>
    ```

    For example:

    ``` { .text }
    http://192.168.0.1:32556
    ```

    Now you can proceed to the next chapter to deploy your pod.
    See [demo workload deployment](../03/demo_workload_deployment.md).


## Cleanup

This section provides commands to remove the deployed components step by step from the Kubernetes cluster.
First, you should [uninstall Trustee](#uninstall-trustee), then [uninstall Confidential Containers](#uninstall-confidential-containers).


### Uninstall Trustee

Depending on what attestation service you have used, you can uninstall the Trustee by following the steps below:

1. Set `DEPLOYMENT_DIR` variable depending on the attestation service used during deployment:

    === ":gear: Intel Trust Authority"

        ``` { .bash }
        export DEPLOYMENT_DIR=ita
        ```

    === ":gear: Intel DCAP"

        ``` { .bash }
        export DEPLOYMENT_DIR=custom_pccs
        ```

2. Delete the Trustee:

    ``` { .bash }
    kubectl delete -k "$DEPLOYMENT_DIR"
    ```


### Uninstall Confidential Containers

To uninstall Confidential Containers, you can delete the deployed Helm release using the following commands:

1. List deployed Confidential Containers Helm charts:

    ``` { .bash }
    export HELM_COCO_CHART_NAME=$(helm list -n coco-system --short)
    ```

2. Delete Confidential Containers related Helm chart:

    ``` { .bash }
    helm uninstall ${HELM_COCO_CHART_NAME} --namespace coco-system
    ```

3. Delete Confidential Containers related namespace:

    ``` { .bash }
    kubectl delete namespace coco-system
    ```