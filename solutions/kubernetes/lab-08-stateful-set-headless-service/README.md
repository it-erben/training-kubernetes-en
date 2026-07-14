# Solution: StatefulSet + Headless Service

```bash
kubectl apply -f manifest.yaml
kubectl get service nginx-headless
kubectl get pod --selector=app=nginx -o wide

kubectl debug nginx-0 -it --image=busybox
nslookup nginx-headless.default.svc.cluster.local
nslookup nginx-0.nginx-headless.default.svc.cluster.local
exit

kubectl delete statefulset.apps/nginx
kubectl delete service/nginx-headless
```

Expected result: the headless service returns three A records (one per pod); querying individual pods returns
pod-specific IPs.
