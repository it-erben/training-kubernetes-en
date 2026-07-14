# Solution: Creating and Modifying Pods

## Part 1

- Namespace: `kubectl create namespace ckad`
- Create the pod: `kubectl run nginx --image=nginx:1.29 --port=80 -n ckad --labels app=nginx`
- Check the details: `kubectl get pod/nginx -n ckad -o wide` and `kubectl describe pod/nginx -n ckad`
- Test availability: determine the pod IP with `kubectl get pod -o wide`, then
  `kubectl run -it tmp --rm --restart=Never --image=busybox:1.37 -n ckad -- wget -qO- http://<IP>`
- View the logs: `kubectl logs nginx -n ckad`
- Add environment variables (pod env is immutable, so delete and recreate the pod):

  ```bash
  kubectl delete pod nginx -n ckad
  kubectl run nginx --image=nginx:1.29 --port=80 -n ckad \
    --env DB_URL="postgresql://mydb:5432" --env DB_USERNAME=admin
  ```

- Shell into the container: `kubectl exec -it nginx -n ckad -- /bin/sh` → `ls -l`, `printenv`, then `exit`

## Part 2

1. Apply the manifest: `kubectl apply -f loop-pod.yaml`
2. Check the status: `kubectl get pod loop -n default` and `kubectl describe pod/loop`
3. Switch to the infinite-loop variant: `kubectl delete pod loop && kubectl apply -f loop-pod-date.yaml`
4. Events/logs: `kubectl get events --field-selector involvedObject.name=loop` and `kubectl logs loop`

The matching YAML files are in this directory.
