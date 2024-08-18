# RBAC mit Pods
In dieser Aufgabe lernt ihr, einem Pod mittels eines ServiceAccounts ein Recht zu geben, dass es normalerweise nicht hat: über die Kubernetes-API andere Pods abfragen.

## 1) Pod anlegen
Schaue dir das [Manifest für den ersten Pod](./pod1.yaml) an. Der Pod definiert ein Container, dessen Image kubectl enthält. Wende das Manifest nun an:

```shell
kubectl apply -f pod1.yaml
```

Es sollte nun ein neuer Pod namens "kubectl-pod" im default-Namespace laufen:

```shell
kubectl get pods
# NAME          READY   STATUS      RESTARTS   AGE
# kubectl-pod   1/1     Running     0          52s
```

Versuchen wir nun, ob dieser Pod auch die anderen Pods per kubectl abfragen darf. Bauen wir dazu zunächst eine Verbindung mit dem Container auf und öffnen eine Shell-Sitzung:
```shell
kubectl exec -it kubectl-pod -- bash
```

Nun versuchen wir in der Shell-Sitzung mit kubectl die Pods des default-Namespaces aufzulisten:
```shell
kubectl get pods
# Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:default" cannot list resource "pods" in API group "" in the namespace "default"
```
Um dieses Ergebnis zu verstehen, müssen wir uns eine Sache in Erinnerung rufen:
Wir haben diesen Befehl gerade **nicht** auf unserem Schulungsrechner ausgeführt, sondern **innerhalb** des Pods.
kubectl innerhalb des Pods hat standardmäßig gar keine Rechte – anders als auf dem Schulungsrechner, wo Minikube uns als Admin konfiguriert hat.
Da kubectl innerhalb des Pods keine Rechte hat, kann es auch keine Pods auflisten.

Trennt die Verbindung nun mit `exit` und löscht den Pod:

```shell
kubectl delete pod kubectl-pod
```

## 2) Service Account, Role und RoleBinding anlegen
Damit der Pod Zugriff erhält, braucht er einen ServiceAccount. Dieser Account muss mit Hilfe einer Rolle das Recht erhalten, Pods aufzulisten.

Schaut euch dazu [folgendes Manifest](./sa.yaml) an. 
Erstens wird dort ein **ServiceAccount** angelegt. 
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-kubectl-sa
```

Der interessantere Teil ist aber die **Rolle**.
```yaml
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```
Sie erlaubt es, pods aufzulisten im default-Namespace, da kein anderer Namespace angegeben ist.
Das **RoleBinding** verbindet die Rolle mit dem ServiceAccount.
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
subjects:
- kind: ServiceAccount
  name: my-kubectl-sa
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Wenn ihr alle Teile verstanden habt, wendet das Manifest nun an:

```shell
kubectl apply -f sa.yaml
```

## 3) Pod mit Service Account starten
In [pod2.yaml](./pod2.yaml) findet ihr ein Manifest für den gleichen Pod wie in Schritt 1 – nur dass diesmal der ServiceAccount genutzt wird, den wir in Schritt 2 angelegt haben:

```yaml
spec:
  serviceAccountName: my-kubectl-sa
  containers:
  - name: kubectl-container
    image: bitnami/kubectl:latest
    command: ["/bin/sh", "-c", "trap : TERM INT; sleep infinity & wait"]
  restartPolicy: Always
```

Wendet das Manifest nun an und verbindet euch dann wieder mit dem Pod:
```shell
kubectl apply -f pod2.yaml
kubectl exec -it kubectl-pod -- bash
```
Führt in der Shell-Sitzung nun wieder kubectl aus, um alle Pods aufzulisten. Es sollte nun funktionieren:

```shell
kubectl get pods
# NAME          READY   STATUS      RESTARTS   AGE
# busybox       0/1     Completed   0          21h
# busybox2      0/1     Error       0          21h
# kubectl-pod   1/1     Running     0          52s
```

## Aufräumen
Löscht zuletzt den Test-Pod:
```shell
kubectl delete pod kubectl-pod
```

