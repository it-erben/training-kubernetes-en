# Working with ConfigMaps

In this series of tasks, we'll learn how to work with **ConfigMaps**. Almost all concepts covered for ConfigMaps can later be applied to **Secrets**.

-----

## Exercise 1: Creating a ConfigMap

We will create a ConfigMap named **`my-config`** that contains two key-value pairs: **`key1: value1`** and **`key2: value2`**.

We'll use both the **imperative** and **declarative** methods to create the ConfigMap.

### Imperative Method

The following command creates a ConfigMap named "my-config" and includes two key-value combinations.

```bash
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2
```

Now, display the content of the new ConfigMap:

```shell
kubectl get configmap my-config -o "jsonpath= {.data.key1}"
```

The `jsonpath` command is used to directly find and output the value of the key `key1`. To better understand why `.data.key` is passed, you can output the content without `jsonpath`:

```shell
kubectl get configmap my-config -o json
```

You will see that the key-value combinations are contained within the **`data`** sub-field.

To delete the ConfigMap afterwards:

```shell
kubectl delete configmap my-config
```

### Declarative Method

The file [declarative-config.yaml](https://www.google.com/search?q=declarative-config.yaml) contains the same ConfigMap we created above, in YAML format. We can apply it directly using `kubectl`.

```bash
kubectl apply -f declarative-config.yaml
```

Now, output the content of the new ConfigMap to verify that the result is as expected:

```shell
kubectl get configmap my-config -o "jsonpath= {.data.key1}"
```

To delete the ConfigMap again:

```bash
kubectl delete configmap my-config
```

-----

## Exercise 2: Using a ConfigMap in a Pod

The file [config-pod.yaml](https://www.google.com/search?q=config-pod.yaml) contains the declarations for a ConfigMap as well as a Pod. The Pod logs its **environment variables (`env`)** and then stops. We can see the result in the logs.

```bash
kubectl apply -f config-pod.yaml
```

Now, let's check the Pod logs to see if the environment variables are truly present:

```bash
kubectl logs config-pod
```

In the logs, you will see all the environment variables known to the Pod. **`key1`** and **`key2`** should be included among them.

Cleanup:

```bash
kubectl delete configmap my-config
```

-----

## Exercise 3: Mapping ConfigMap Values to a Volume

The file [volume-pod.yaml](https://www.google.com/search?q=volume-pod.yaml) contains a ConfigMap that is mounted into a Pod via a **Volume**. As in the previous example, the result is logged, but the container waits for some time before stopping. This allows us to inspect it using `exec`.

Apply the file:

```bash
kubectl apply -f volume-pod.yaml
```

We now check whether the files were successfully mounted into the Pod:

```bash
kubectl exec -it volume-pod -- ls /etc/config
```

```bash
kubectl exec -it volume-pod -- cat /etc/config/key1
```

In the first case, you will see all files created as part of the mounting process. The second command uses `cat` to output the content of the file **`key1`**, which contains the first configuration value.

Pause for a moment and recognize that Kubernetes provides the Pod with a **separate file for every key-value pair** in the ConfigMap. Each file contains the corresponding value specified in the ConfigMap.

Cleanup:

```shell
kubectl delete configmap/my-config
kubectl delete pod/volume-pod
```

### Documentation

* [ConfigMap Documentation](https://kubernetes.io/docs/concepts/configuration/configmap/)
* [Secret Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
