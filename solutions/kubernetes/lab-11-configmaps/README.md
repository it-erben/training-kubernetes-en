# Solution: ConfigMaps

## Exercise 1

```bash
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2
kubectl get configmap my-config -o "jsonpath={.data.key1}"
kubectl delete configmap my-config
kubectl apply -f declarative-config.yaml
kubectl get configmap my-config -o "jsonpath={.data.key1}"
```

## Exercise 2

```bash
kubectl apply -f config-pod.yaml
kubectl logs config-pod   # key1/key2 appear as env variables
kubectl delete pod/config-pod configmap/my-config
```

## Exercise 3

```bash
kubectl apply -f volume-pod.yaml
kubectl exec -it volume-pod -- ls /etc/config
kubectl exec -it volume-pod -- cat /etc/config/key1
kubectl delete pod/volume-pod configmap/my-config
```
