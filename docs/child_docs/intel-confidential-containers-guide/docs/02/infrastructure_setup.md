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

2. [Install Confidential Containers Operator](#install-confidential-containers-operator)

    We explore how to deploy Kata Containers, a lightweight container runtime, to allow running containers as lightweight VMs, or VMs with Intel TDX protection (i.e., TDs).
    We can achieve this by installation of the Confidential Containers operator, which provides a means to deploy and manage Confidential Containers Runtime on Kubernetes cluster.

3. [Install Attestation Components](#install-attestation-components)

    We discuss how to deploy attestation components that ensure that the pods are running the expected workloads, that the pods are protected by Intel TDX on a genuine Intel platform, that the platform is patched to a certain level, and that certain other security relevant information is as expected.
    As an example, we show how to integrate different attestation services into the Confidential Containers Key Broker Service (KBS): Intel® Trust Authority and an Intel® DCAP-based attestation service.

4. [Cleanup](#cleanup)

    We provide commands to remove the deployed components step by step from the Kubernetes cluster.


## Prerequisites

This section describes the prerequisites that we assume for the following steps regarding installed software and optionally access to an Intel Trust Authority API Key.


### Installed Software

Ensure that your infrastructure meets the following requirements:

- [Kubernetes](https://kubernetes.io/) - 1.29.5 or newer.
- Kubernetes cluster with at least one node - serving as master and worker node.
- [containerd](https://containerd.io/) 1.7.12 or newer.
- Worker nodes configured on [registered](../../../intel-tdx-enabling-guide/02/infrastructure_setup/#platform-registration) Intel platforms with Intel TDX Module version 1.5.

    !!! note "Intel TDX Enabling"
        The registration of Intel platform referred above does not yet fully cover Ubuntu 24.04.
        For additional details, refer to [Canonical's guide](https://github.com/canonical/tdx/blob/3.3/README.md) to configure Intel TDX.
        Especially, the [remote attestation chapter](https://github.com/canonical/tdx/blob/3.3/README.md#setup-remote-attestation) provides details about the configuration of remote attestation.


### Intel Trust Authority API Key

!!! note
    This is optional step only if you want to use Intel Trust Authority as an attestation service.

To enable remote attestation of applications as explained in the following chapter, you need to have access to an Intel Trust Authority API Key (later referred to as `ITA_API_KEY`).

If you do not yet have such a key, you will find instructions on the [Intel Trust Authority website](https://www.intel.com/content/www/us/en/security/trust-authority.html).
In particular, you will find the option to start a free trial.


## Install Confidential Containers Operator

In this section, we will deploy all required components to run containers as lightweight VMs with Intel TDX protection (i.e., TDs).
In particular, we install the Confidential Containers operator, which is used to deploy and manage the Confidential Containers Runtime on Kubernetes clusters.
For more details, see the complete instruction in the [CoCo Operator Quick Start](https://github.com/confidential-containers/confidential-containers/blob/main/quickstart.md#operator-installation).

Steps:

1. Ensure your cluster's node is labeled:

     ``` { .bash }
     kubectl label node $(kubectl get nodes | awk 'NR!=1 { print $1 }') node.kubernetes.io/worker=
     ```

2. Set the environment variable `OPERATOR_RELEASE_VERSION` to the version of the Confidential Containers operator that you want to use.
    All available versions can be found [on the corresponding GitHub page](https://github.com/confidential-containers/operator/tags).
    Note that we tested this guide with the version `v0.14.0`.

     ``` { .bash }
     export OPERATOR_RELEASE_VERSION=v0.14.0
     ```

3. Deploy the Confidential Containers operator:

    ``` { .bash }
    kubectl apply -k "github.com/confidential-containers/operator/config/release?ref=$OPERATOR_RELEASE_VERSION"
    ```

4. Wait until the deployment is available:

    ``` { .bash }
    kubectl wait -n confidential-containers-system --for=condition=available --timeout=5m deployment/cc-operator-controller-manager
    ```

    Expected output:

    ``` { .text }
    deployment.apps/cc-operator-controller-manager condition met
    ```

5. Create Confidential Containers related runtime classes:

    === ":gear: no proxy"

         ``` { .bash }
         kubectl apply -k "github.com/confidential-containers/operator/config/samples/ccruntime/default?ref=$OPERATOR_RELEASE_VERSION"
         ```

    === ":gear: with proxy"

         Set the following environmental variables:

         - `https_proxy`: value to your proxy URL.
         - `no_proxy`: value to exclude traffic from using the proxy.

         ``` { .bash }
         mkdir -p /tmp/proxy-overlay; \
         pushd /tmp/proxy-overlay
         cat <<EOF > kustomization.yaml
         apiVersion: kustomize.config.k8s.io/v1beta1
         kind: Kustomization
         resources:
           - github.com/confidential-containers/operator/config/samples/ccruntime/default?ref=$OPERATOR_RELEASE_VERSION
         patches:
         - patch: |-
             - op: add
               path: /spec/config/environmentVariables/-
               value:
                 name: AGENT_HTTPS_PROXY
                 value: ${https_proxy}
             - op: add
               path: /spec/config/environmentVariables/-
               value:
                 name: AGENT_NO_PROXY
                 value: ${no_proxy}
           target:
             kind: CcRuntime
             name: ccruntime-sample

         EOF
         popd
         kubectl apply -k /tmp/proxy-overlay
         rm -rf /tmp/proxy-overlay
         ```

6. Wait until Confidential Containers operator pods are ready:

    ``` { .bash }
    kubectl -n confidential-containers-system wait --for=condition=Ready pods --all --timeout=5m
    ```

    Expected output:

     ``` { .text }
     pod/cc-operator-controller-manager-b6dcb65fb-7lmz8 condition met
     pod/cc-operator-daemon-install-2n6sq condition met
     pod/cc-operator-pre-install-daemon-9xvzf condition met
     ```

7. Check that the Confidential Containers runtime classes exist:

    ``` { .bash }
    kubectl get runtimeclass | grep -i kata
    ```

    Expected output:

    ``` { .text }
    kata                 kata-qemu            12s
    kata-clh             kata-clh             12s
    kata-qemu            kata-qemu            12s
    kata-qemu-coco-dev   kata-qemu-coco-dev   12s
    kata-qemu-sev        kata-qemu-sev        12s
    kata-qemu-snp        kata-qemu-snp        12s
    kata-qemu-tdx        kata-qemu-tdx        12s
    ```


## Install Attestation Components

In this section, we explore how to deploy attestation components that ensure that the pods are running the expected workloads, that the pods are protected by Intel TDX on a genuine Intel platform, that the platform is patched to a certain level, and that certain other security relevant information is as expected.
As an example, we show how to integrate different attestation services into the KBS, specifically:

- [Intel® Trust Authority](https://www.intel.com/content/www/us/en/security/trust-authority.html)
- [Intel® DCAP-based attestation service](https://github.com/intel/confidential-computing.tee.dcap)

Steps:

1. Clone the Confidential Containers Trustee repository using the following command.
    Note that this guide was tested with version v0.13.0, but newer [versions](https://github.com/confidential-containers/trustee/releases) might be available.

    ``` { .bash }
    git clone -b v0.13.0 https://github.com/confidential-containers/trustee
    cd trustee/kbs/config/kubernetes/
    ```

2. Configure Key Broker Service according to the used attestation service variant:

    === ":gear: Intel Trust Authority"

         - To configure the Key Broker Services to use Intel Trust Authority as an attestation service, set the environment variable `DEPLOYMENT_DIR` as follows:

             ``` { .bash }
             export DEPLOYMENT_DIR=ita
             ```

         - Set your Intel Trust Authority API Key in KBS configuration:

             ``` { .bash }
             sed -i 's/api_key =.*/api_key = "'${ITA_API_KEY}'"/g' $DEPLOYMENT_DIR/kbs-config.toml
             ```

         - If your network requires the usage of a proxy to access the Intel® Trust Authority service, you may need to set the `HTTPS_PROXY` environment variable in KBS deployment.
           This can be done with the following command:

             ``` { .bash }
             sed -i "s|^\(\s*\)volumes:|\1  env:\n\1    - name: https_proxy\n\1      value: \"$https_proxy\"\n\1volumes:|" base/deployment.yaml
             ```

    === ":gear: Intel DCAP"

         - To configure the Key Broker Services to use Intel DCAP as an attestation service, set the environment variable `DEPLOYMENT_DIR` as follows:

             ``` { .bash }
             export DEPLOYMENT_DIR=custom_pccs
             ```

3. Update your secret key that is required during deployment:

    ``` { .bash }
    echo "This is my super secret" > overlays/key.bin
    ```

4. Deploy Key Broker Service:

    ``` { .bash }
    ./deploy-kbs.sh
    ```

    Validate whether KBS pod is running:

    ``` { .bash }
    kubectl get pods -n coco-tenant
    ```

    Expected output:

    ``` { .bash }
    NAME                   READY   STATUS    RESTARTS   AGE
    kbs-5f4696986b-64ljx   1/1     Running   0          12s
    ```

5. Retrieve `KBS_ADDRESS` for future use in pod's yaml file:

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
    See [demo workload deployment](../03/demo_workload_deployment.md)


## Cleanup

This section provides commands to remove the deployed components step by step from the Kubernetes cluster.
After [uninstalling Key Broker Service](#uninstall-key-broker-service), follow [uninstalling Confidential Containers Operator](#uninstall-confidential-containers-operator).


### Uninstall Key Broker Service

Depending on what attestation service you have used, you can uninstall the Key Broker Service by following the steps below:

1. Set `DEPLOYMENT_DIR` variable depending on the attestation service used during deployment:

    === ":gear: Intel Trust Authority"

         ``` { .bash }
         export DEPLOYMENT_DIR=ita
         ```

    === ":gear: Intel DCAP"

         ``` { .bash }
         export DEPLOYMENT_DIR=custom_pccs
         ```

2. Delete the Key Broker Service:

    ``` { .bash }
    kubectl delete -k "$DEPLOYMENT_DIR"
    ```


### Uninstall Confidential Containers Operator

1. Set environment variable `OPERATOR_RELEASE_VERSION` to installed operator version:

    ``` { .bash }
    export OPERATOR_RELEASE_VERSION=$(kubectl get deployment cc-operator-controller-manager -n confidential-containers-system -o jsonpath="{.spec.template.spec.containers[?(@.name=='manager')].image}" | cut -d: -f2)
    ```

2. Delete Confidential Containers-related runtime classes:

    ``` { .bash }
    kubectl delete -k "github.com/confidential-containers/operator/config/samples/ccruntime/default?ref=$OPERATOR_RELEASE_VERSION"
    ```

3. Delete the Confidential Containers operator:

    ``` { .bash }
    kubectl delete -k "github.com/confidential-containers/operator/config/release?ref=$OPERATOR_RELEASE_VERSION"
    ```
