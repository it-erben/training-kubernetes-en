# Solution: Volumes

## Task 1: Ephemeral Volume

- Apply the manifest: `kubectl apply -f emptydir-two-containers.yaml`
- Create the file:
  `kubectl exec -it emptydir-demo -c c1 -- sh -c "mkdir -p /etc/a/data && echo 'Hello World.' > /etc/a/data/hello.txt"`
- Cross-check: `kubectl exec -it emptydir-demo -c c2 -- cat /etc/b/data/hello.txt`
- Clean up: `kubectl delete pod emptydir-demo`

## Task 2: Persistent Volumes

- Create PV/PVC/pod: `kubectl apply -f logs-pv-pvc-pod.yaml`
- Check the status: `kubectl get pv/logs-pv pvc/logs-pvc`
- Write a file: `kubectl exec -it logs-nginx -- sh -c "echo run1 > /var/log/nginx/mynginx.log"`
- Recreate the pod: `kubectl delete pod logs-nginx && kubectl apply -f logs-pv-pvc-pod.yaml`
- Verify persistence: `kubectl exec -it logs-nginx -- cat /var/log/nginx/mynginx.log`
