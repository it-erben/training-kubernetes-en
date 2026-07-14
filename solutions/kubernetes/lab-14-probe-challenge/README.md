# Solution: Probes and Lifecycle

- Adjust and apply the manifest: `kubectl apply -f web-server.yaml`
- Watch the startup: `kubectl get pod web-server -w`
- Details: `kubectl describe pod/web-server`
- Check the events: `kubectl get events --field-selector involvedObject.name=web-server`
- Once Ready: `kubectl logs web-server` or `kubectl exec -it web-server -- curl -sf localhost`
