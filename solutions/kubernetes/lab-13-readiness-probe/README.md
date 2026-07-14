# Solution: Fixing the Readiness Probe

The probe in the exercise manifest points at the wrong port. Apply the corrected manifest:

```bash
kubectl apply -f manifest-fixed.yaml
kubectl get pods -l app=readiness-check-demo
kubectl run -it --rm debug --image=busybox --restart=Never -- sh -c "wget -q -O- readiness-check-demo-svc.default.svc.cluster.local"
```

The readiness probe now uses port 80; the pods become `READY 1/1` and the service responds.
