# Test kernel to Ethernet to kernel connection

This is a simple traffic test on 4 worker nodes Kernel2Kernel and Kernel2Ethernet2Kernel topology

## Requires

kind running with 4 worker

Make sure that you have completed steps from [basic](../../basic)  setup.

## Run

Scale the registry:

```bash
kubectl scale deployment -n nsm-system  registry-k8s --replicas=2
```

Wait for registry to be ready:

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=registry -n nsm-system
```

Deploy NSC and NSE:

```bash
kubectl apply -k .
```

Wait for applications ready:

```bash
APP_NS=ns-kernel-mech-traffic
kubectl wait --for=condition=ready --timeout=1m pod -l app=iperf-server-1 -n $APP_NS
```

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=iperf-server-2 -n $APP_NS
```

```bash
kubectl wait --for=condition=ready --timeout=1m pod -l app=nse-kernel-1 -n $APP_NS
```

Start IPv4 iperf server on NSCs and start some traffic from NSE

```
for nsc in $(kubectl get pods -l app=iperf-server-1 -n ${APP_NS} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'); do
NSC_IP=$(kubectl exec -n ${APP_NS} ${nsc} -c cmd-nsc -- ip a s dev nsm-1 | grep 'inet ' | cut -f 6 -d ' ' | cut -f1 -d'/')
echo "nsc: ${nsc} : ${NSC_IP}";
kubectl exec -n ${APP_NS} ${nsc} -c iperf -- bash -c "iperf3 -sD -B ${NSC_IP} -i20 --timestamps \"%H:%M:%S\" --logfile /tmp/iperf-${nsc}.log &"
for nse in $(kubectl get pods -l app=nse-kernel-1 -n ${APP_NS} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'); do
kubectl exec -n ${APP_NS} ${nse} -c iperf -- bash -c "iperf3 -i0 -t 25 -c ${NSC_IP} --timestamps \"%H:%M:%S\" --logfile /tmp/iperf-${nse}-${nsc}.log &" &
done
done
```

Start IPv6 iperf server on NSCs and start some traffic from NSE

```
for nsc in $(kubectl get pods -l app=iperf-server-2 -n ${APP_NS} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'); do
NSC_IP=$(kubectl exec -n ${APP_NS} ${nsc} -c cmd-nsc -- ip a s dev nsm-2 | grep 'inet6 ' | cut -f 6 -d ' ' | cut -f1 -d'/'| grep ^100)
echo "nsc: ${nsc} : ${NSC_IP}";
kubectl exec -n ${APP_NS} ${nsc} -c iperf -- bash -c "iperf3 -sD -B ${NSC_IP} -i20 --timestamps \"%H:%M:%S\" --logfile /tmp/iperf-${nsc}.log &"
for nse in $(kubectl get pods -l app=nse-kernel-2 -n ${APP_NS} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'); do
kubectl exec -n ${APP_NS} ${nse} -c iperf -- bash -c "iperf3 -i0 -t 25 -c ${NSC_IP} --timestamps \"%H:%M:%S\" --logfile /tmp/iperf-${nse}-${nsc}.log &" &
done
done
```


Wait and check the logs

```
sleep 30
for nse in $(kubectl get pods -l app=nse-kernel-1 -n ${APP_NS} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'); do kubectl exec -n ${APP_NS} ${nse} -c iperf -- bash -c 'for logf in /tmp/iperf-*; do echo $logf; cat $logf; done'; done
for nse in $(kubectl get pods -l app=nse-kernel-2 -n ${APP_NS} --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'); do kubectl exec -n ${APP_NS} ${nse} -c iperf -- bash -c 'for logf in /tmp/iperf-*; do echo $logf; cat $logf; done'; done
```

## Cleanup

Delete ns:

```bash
kubectl delete ns $APP_NS
```
