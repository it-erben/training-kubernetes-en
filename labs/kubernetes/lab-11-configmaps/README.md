# Lab 11: Working with ConfigMaps

In this series of tasks we will learn how to work with ConfigMaps. Almost all ConfigMap concepts can later
be transferred to Secrets.

## Exercise 1: Creating a ConfigMap

We create a ConfigMap named my-config containing two key-value pairs: `key1: value1` and
`key2: value2`.

We will use both imperative and declarative methods to create the ConfigMap.

### Imperative method

The following command creates a ConfigMap named "my-config" containing two key-value combinations.

```bash
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2
```

Now display the contents of the new ConfigMap:

```shell
kubectl get configmap my-config -o "jsonpath= {.data.key1}"
```

`jsonpath` is used here to pick out and print the value of the key `key1` directly. To understand more
precisely why `.data.key` is passed, you can display the contents without `jsonpath`:

```shell
kubectl get configmap my-config -o json
```

You will see that the key-value combinations are contained in the `data` subfield.

To delete the ConfigMap afterwards:

```shell
kubectl delete configmap my-config
```

### Declarative method

The file [declarative-config.yaml](declarative-config.yaml) contains the same ConfigMap we created above,
as YAML. We can apply it directly with kubectl.

**`declarative-config.yaml`:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  key1: "value1"
  key2: "value2"
```

```bash
kubectl apply -f declarative-config.yaml
```

Now display the contents of the new ConfigMap to verify that the result is as expected:

```shell
kubectl get configmap my-config -o "jsonpath= {.data.key1}"
```

To delete the ConfigMap again:

```bash
kubectl delete configmap my-config
```

## Exercise 2: Using a ConfigMap in a pod

The file [config-pod.yaml](config-pod.yaml) contains the declarations of a ConfigMap and a pod. The pod logs the
`env` output and then stops. We can see the result in the logs.

**`config-pod.yaml`:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  key1: "value1"
  key2: "value2"
---
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
spec:
  containers:
    - name: busybox
      image: busybox:1.36.1
      command: ["sh", "-c", "env"]
      envFrom:
        - configMapRef:
            name: my-config
      readinessProbe:
        exec:
          command: ["sh", "-c", "true"]
        initialDelaySeconds: 1
        periodSeconds: 10
      livenessProbe:
        exec:
          command: ["sh", "-c", "true"]
        initialDelaySeconds: 5
        periodSeconds: 20
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
  restartPolicy: Never
```

```bash
kubectl apply -f config-pod.yaml
```

Now let's check the pod logs to see whether the environment variables are really present:

```bash
kubectl logs config-pod
```

In the logs you will see all environment variables the pod knows. Among others, `key1` and `key2` should
be included.

Cleaning up:

```bash
kubectl delete configmap my-config
```

## Exercise 3: Mapping ConfigMap values to volumes

The file [volume-pod.yaml](volume-pod.yaml) contains a ConfigMap that is mounted into a pod via a volume. As in
the exercise before last, the result is logged, but the container waits a while before stopping. So we can
inspect it with exec.

**`volume-pod.yaml`:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  key1: "value1"
  key2: "value2"
---
apiVersion: v1
kind: Pod
metadata:
  name: volume-pod
spec:
  containers:
    - name: busybox
      image: busybox:1.36.1
      command: ["sleep", "3600"]
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      readinessProbe:
        exec:
          command: ["sh", "-c", "true"]
        initialDelaySeconds: 1
        periodSeconds: 10
      livenessProbe:
        exec:
          command: ["sh", "-c", "true"]
        initialDelaySeconds: 5
        periodSeconds: 20
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
  volumes:
    - name: config-volume
      configMap:
        name: my-config
  restartPolicy: Never
```

Applying the file:

```bash
kubectl apply -f volume-pod.yaml
```

We now check whether the files were successfully mounted into the pod:

```bash
kubectl exec -it volume-pod -- ls /etc/config
```

```bash
kubectl exec -it volume-pod -- cat /etc/config/key1
```

In the first case you see all files that were created as part of the mount. The second command uses `cat` to print
the contents of the file `key1`, which contains the first configuration value.

Now pause for a moment and consider that Kubernetes provides the pod with one file for each
key-value combination in the ConfigMap. Each file contains the value specified in the
ConfigMap.

Cleaning up:

```shell
kubectl delete configmap/my-config
kubectl delete pod/volume-pod
```

### Bonus

- [https://kubernetes.io/docs/concepts/configuration/configmap/](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [https://kubernetes.io/docs/concepts/configuration/secret/](https://kubernetes.io/docs/concepts/configuration/secret/)
