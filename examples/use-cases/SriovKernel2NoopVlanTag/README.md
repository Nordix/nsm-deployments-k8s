# Test SR-IOV kernel VLAN tagged connection

**_Note: 802.1Q must be enabled on your cluster_**

This example shows that NSC and NSE can work with each other over the SR-IOV kernel connection.

## Requires

Make sure that you have completed steps from [sriov](../../sriov_vlantag) setup.

## Run

Deploy ponger:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/SriovKernel2NoopVlanTag/ponger?ref=2dded6462a931508a912f1a100c7c21e740ebda7
```

Wait for applications ready:
```bash
kubectl -n ns-sriov-kernel2noop-vlantag wait --for=condition=ready --timeout=1m pod -l app=ponger
```

Wait for the ponger configuration to be applied:
```bash
kubectl -n ns-sriov-kernel2noop-vlantag exec deploy/ponger -- ip a | grep "172.16.1.100"
```

Deploy NSC and NSE:
```bash
kubectl apply -k https://github.com/networkservicemesh/deployments-k8s/examples/use-cases/SriovKernel2NoopVlanTag?ref=2dded6462a931508a912f1a100c7c21e740ebda7
```

Wait for applications ready:
```bash
kubectl -n ns-sriov-kernel2noop-vlantag wait --for=condition=ready --timeout=1m pod -l app=nsc-kernel
```
```bash
kubectl -n ns-sriov-kernel2noop-vlantag wait --for=condition=ready --timeout=1m pod -l app=nse-noop
```

Ping from NSC to NSE:
```bash
kubectl -n ns-sriov-kernel2noop-vlantag exec deployments/nsc-kernel -- ping -c 4 172.16.1.100
```

## Cleanup

Delete ns:
```bash
kubectl delete ns ns-sriov-kernel2noop-vlantag
```
