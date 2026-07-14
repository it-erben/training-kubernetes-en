# Lab 11: Working with ConfigMaps

In this series of tasks we'll learn how to work with ConfigMaps. Almost everything about ConfigMaps
carries over to Secrets later.

## Exercise 1: Creating a ConfigMap

We'll create a ConfigMap named my-config with two key-value pairs: `key1: value1` and
`key2: value2`.

We'll create it both ways: imperatively and declaratively.

### Imperative method

The following command creates a ConfigMap named "my-config" with two key-value pairs.

```bash
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2
```

Now display the contents of the new ConfigMap:

```shell
kubectl get configmap my-config -o "jsonpath= {.data.key1}"
```

Here, `jsonpath` picks out the value of the key `key1` and prints it directly. To see why
`.data.key` is passed, print the contents without `jsonpath`:

```shell
kubectl get configmap my-config -o json
```

You'll see that the key-value pairs live in the `data` field.

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

Now display the contents of the new ConfigMap to check that everything looks as expected:

```shell
kubectl get configmap my-config -o "jsonpath= {.data.key1}"
```

To delete the ConfigMap again:

```bash
kubectl delete configmap my-config
```

## Exercise 2: Using a ConfigMap in a pod

The file [config-pod.yaml](config-pod.yaml) declares a ConfigMap and a pod. The pod logs the
`env` output and then stops, so we can see the result in the logs.

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

Now let's check the pod logs to see whether the environment variables are actually there:

```bash
kubectl logs config-pod
```

The logs show every environment variable set in the pod. `key1` and `key2` should be among
them.

Cleaning up:

```bash
kubectl delete configmap my-config
```

## Exercise 3: Mapping ConfigMap values to volumes

The file [volume-pod.yaml](volume-pod.yaml) contains a ConfigMap that gets mounted into a pod as a volume. As in
the exercise before last, the result is logged, but this time the container sticks around for a while before
stopping, so we can inspect it with exec.

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

Now let's check that the files actually made it into the pod:

```bash
kubectl exec -it volume-pod -- ls /etc/config
```

```bash
kubectl exec -it volume-pod -- cat /etc/config/key1
```

The first command lists all files created by the mount. The second uses `cat` to print
the contents of the file `key1`, which holds the first configuration value.

Take a moment to notice what happened here: Kubernetes gives the pod one file per
key-value pair in the ConfigMap, and each file contains the corresponding value.

Cleaning up:

```shell
kubectl delete configmap/my-config
kubectl delete pod/volume-pod
```

### Bonus

- [https://kubernetes.io/docs/concepts/configuration/configmap/](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [https://kubernetes.io/docs/concepts/configuration/secret/](https://kubernetes.io/docs/concepts/configuration/secret/)
