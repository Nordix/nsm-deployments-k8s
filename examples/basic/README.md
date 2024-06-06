# Basic examples
-
Contain basic setup for NSM that includes `nsmgr`, `forwarder-vpp`, `registry-k8s`. `forwarder-vpp` is special since starts with external vpp. Vpp running in different pod.

## Requires

- [spire](../spire/single_cluster/)

- local forwarder image patched

```bash
/networkservicemesh/cmd-forwarder-vpp (v1.13.1-rc.4)
> git diff
diff --git a/main.go b/main.go
index 7a1087d..118e272 100644
--- a/main.go
+++ b/main.go
@@ -178,7 +178,7 @@ func main() {
                cleanupOpts = append(cleanupOpts, cleanup.WithDoneChan(cleanupDoneCh))
                log.FromContext(ctx).Info("external vpp is being used")
 
-               if err = cfg.VppInit.Decode("NONE"); err != nil {
+               if err = cfg.VppInit.Decode("AF_PACKET"); err != nil {
                        log.FromContext(ctx).Fatalf("VppInit.Decode error: %v", err)
                }
        } else { // If we don't have a VPPAPISocket, start VPP and use that
```

- cmd-forwarder-vpp:local image built and loaded to kind

```bash
/networkservicemesh/cmd-forwarder-vpp (v1.13.1-rc.4)
 >
docker build . --tag cmd-forwarder-vpp:local

kind load docker-image cmd-forwarder-vpp:local
```

- vpp:local built and loaded to kind

```bash
nsm-deployments-k8s/examples/basic/vpp vpp-sep
 > docker build . --tag vpp:local

kind load docker-image vpp:local
```

## Run

Apply NSM resources for basic tests:

```bash
kubectl apply -k .
```

Wait for admission-webhook-k8s:

```bash
WH=$(kubectl get pods -l app=admission-webhook-k8s -n nsm-system --template '{{range .items
}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl wait --for=condition=ready --timeout=1m pod ${WH} -n nsm-system
```
## Includes

- [Kernel to Kernel Connection](../use-cases/Kernel2Kernel)
- kernel traffic test from 'traffic' branch of https://github.com/Nordix/nsm-deployments-k8s

## Cleanup

To free resources follow the next commands:

```bash
kubectl delete mutatingwebhookconfiguration nsm-mutating-webhook
kubectl delete ns nsm-system
```
