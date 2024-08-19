# Pod Security Standards
In diesem Beispiel wollen wir die Regeln, die ihr im Kurs kennen gelernt hat, einmal selbst testen.

## 1) Namespace anlegen
Der Namespace in [ns.yaml](ns.yaml) enthält Konfigurationen für Warnung und Blockade von Pods auf Basis von Pod Security Standards.
Pods dürfen maximal Rechte in Anspruch nehmen, die der `baseline`-Regel entsprechen. Insbesondere dürfen sie damit keinen priviligierten Zugriff anfordern.
Gewarnt wird, wenn Pods Rechte anfordern, die über die `restricted`-Regel hinausgehen. Der Cluster-Administrator kann diese Warnungen einsehen.

```shell
kubectl apply -f ns.yaml
```

## 2) Pod anlegen, der eine Warnung verursacht
Der Pod in [warn-pod.yaml](./warn-pod.yaml) fordert keine Rechte an, die gegen die `baseline`-Policy verstoßen würden.
Einer seiner Container läuft aber als `root`-User (uid 0), wodurch er über die `restricted`-Policy hinausgeht. Dies erzeugt eine Warnung.
Wenden wir diesen Pod an, quittiert der api-server diesen Vorgang mit einer Warnung, lässt den Pod aber durch:
```shell
kubectl apply -f warn-pod.yaml
# Warning: would violate PodSecurity "restricted:latest": unrestricted capabilities (container "nginx" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "nginx" must set securityContext.runAsNonRoot=true), runAsUser=0 (container "nginx" must not set runAsUser=0), seccompProfile (pod or container "nginx" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
# pod/warning-pod created
```

## 3) Pod anlegen, der Blockiert wird
Der Pod in [error-pod.yaml](./error-pod.yaml) enthält eine Einstellung, die gegen die `baseline`-Policy verstößt: Er fordert den Priviledged-Modus an, wodurch er weitreichenden Zugriff auf den Host erhält.
Der Namespace, den wir oben angelegt haben, ist darauf konfiguriert, solche Pods abzulehnen. Testen wir dies:

```shell
kubectl apply -f error-pod.yaml
# Error from server (Forbidden): error when creating "error-pod.yaml": pods "blocked-pod" is forbidden: violates PodSecurity "baseline:latest": privileged (container "privileged-container" must not set securityContext.privileged=true)
```
Der api-server leht dieses Manifest an, weil es gegen die Pod Security Standards des Namespaces verstößt.

## Aufräumen
```shell
kubectl delete all --all -n my-secure-namespace 
kubectl delete ns my-secure-namespace
```
