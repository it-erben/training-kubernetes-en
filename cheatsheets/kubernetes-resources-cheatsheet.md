## Kubernetes Cheat Sheet: Wichtige Ressourcentypen

### 1. Pods
Ein Pod ist die kleinste und einfachste Einheit in Kubernetes. Er repräsentiert einen laufenden Prozess auf einem Cluster und kann einen oder mehrere Container enthalten.

Dokumentation: [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: my-image
```
### 2. Deployments
Ein Deployment ist eine höhere Abstraktionsebene, die die Verwaltung von Pods und ReplicaSets ermöglicht. Es stellt sicher, dass eine bestimmte Anzahl von Replikaten eines Pods immer verfügbar ist.

Dokumentation: [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-container
          image: my-image
```
### 3. Services
Ein Service ist eine Abstraktion, die eine stabile Netzwerkadresse für die Kommunikation mit Pods bereitstellt. Es definiert Regeln, wie der Netzwerkverkehr an die Pods weitergeleitet wird.

Dokumentation: [Services](https://kubernetes.io/docs/concepts/services-networking/service/)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
```
### 4. ConfigMaps
ConfigMaps ermöglichen es, Konfigurationsdaten von Anwendungscode zu trennen. Sie können als Umgebungsvariablen, Kommandozeilenargumente oder Konfigurationsdateien in einem Volume verwendet werden.

Dokumentation: [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-configmap
data:
  my-key: my-value
```

### 5. Secrets
Secrets sind ähnlich wie ConfigMaps, aber sie werden verwendet, um vertrauliche Informationen wie Passwörter, Tokens oder Schlüssel zu speichern und bereitzustellen.

Dokumentation: [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  my-key: bXktdmFsdWU=  # Base64-encoded value
```

### 6. Volumes
Volumes sind Datenträger, die in einem Pod verwendet werden können, um Daten zwischen Containern zu teilen oder Daten über das Leben eines Containers hinaus zu speichern.

Dokumentation: [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
    - name: my-container
      image: my-image
      volumeMounts:
        - name: my-volume
          mountPath: /data
  volumes:
    - name: my-volume
      emptyDir: {}
```
### 7. Persistent Volumes (PV) und Persistent Volume Claims (PVC)
PVs und PVCs sind Ressourcen, die das Speichern von Daten über das Leben eines Pods hinaus ermöglichen. PVs repräsentieren physische Speicherressourcen, während PVCs Anforderungen an diese Ressourcen sind.

Dokumentation: [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data

---

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```
### 8. StatefulSets
StatefulSets sind für Anwendungen gedacht, die einen stabilen Netzwerknamen und eine stabile Speicherung benötigen. Sie gewährleisten, dass Pods eindeutige und beständige Identitäten haben.

Dokumentation: [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: my-statefulset
spec:
  serviceName: "my-service"
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-container
        image: my-image
```
