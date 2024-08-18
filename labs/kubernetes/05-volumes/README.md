# Persistent Volumes

Die folgende Übungsaufgabe soll dir dabei helfen, ein grundlegendes Verständnis für Volumes in Kubernetes (k8s) zu erhalten. In dieser Übung erstellst du eine Applikation, die in einem Pod läuft und persistenten Speicherplatz in Form eines Volumes verwendet.

**Erstelle die k8s-Ressourcen**

Wie auch in den letzten Beispielen kannst du alle nötigen Ressourcen für diese Übung über die manifest.yaml anlegen:

```shell
kubectl apply -f manifest.yaml
```

Angelegt werden ein Pod mit NGINX, ein Service des Typs `NodePort` der diesen Pod unter Port 30080 auf dem Host verfügbar macht und ein `PersistentVolumeClaim`, mit welchem der Pod ein `PersistentVolume` anfragen wird.

Verwende die folgenden Befehle, um den Status deiner Kubernetes-Ressourcen zu überprüfen:

```sh
kubectl get pv,pvc
kubectl get pods
```

Typische Beispielausgaben:

```sh
# kubectl get pv,pvc
NAME                                                        CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS   CLAIM             STORAGECLASS   REASON   AGE
persistentvolume/pvc-60108e64-6d15-11ec-af1d-0242ac110002   1Gi        RWO           Delete          Bound    default/my-claim  standard                2m

NAME                     STATUS   VOLUME                                     CAPACITY   ACCESSMODES   STORAGECLASS   AGE
persistentvolumeclaim/my-claim   Bound    pvc-60108e64-6d15-11ec-af1d-0242ac110002   1Gi        RWO            standard       2m

# kubectl get pods
NAME     READY   STATUS    RESTARTS   AGE
my-pod    1/1     Running   0          1m
```

Wenn du eine ähnliche Ausgabe erhältst du der Pod den Status `running` hat, kannst du fortfahren. Das kann etwas dauern!

**Erstelle eine `index.html`-Datei auf deinem lokalen Rechner**

Du kannst auch die index.html-Datei verwenden, die in diesem Verzeichnis liegt.

```html
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <title>Meine persönliche Webseite</title>
</head>
<body>
    <h1>Hallo, das ist meine persönliche Webseite!</h1>
    <p>Willkommen auf meiner Webseite, die in einem Kubernetes-Pod mit einem Persistent Volume läuft.</p>
</body>
</html>
```

**Kopiere die `index.html`-Datei in den nginx-Container**:

```sh
kubectl cp index.html my-pod:/usr/share/nginx/html/index.html -c my-container
```

In diesem Befehl ersetzt du `index.html` durch den Pfad zur Datei auf deinem lokalen Rechner. `my-pod` ist der Name des Pods, in den die Datei kopiert werden soll, und `my-container` der Namen des Containers innerhalb des Pods (hier ist es der nginx-Container). Der Zielordner `/usr/share/nginx/html/index.html` ist der in der `pod.yaml` definierte Speicherort innerhalb des Containers.

**Überprüfe, ob die `index.html`-Datei erfolgreich übertragen wurde**

Da wir minikube einsetzen, können wir leider nicht einfach mit http://localhost:30080 auf den Service zugreifen, obwohl wir diesen Port im Service als `NodePort` definiert haben. Wir führen also aus:

```shell
minikube service my-service
```

Im Browser sollten nun die Webseite erscheinen, die wir oben angelegt haben.

## Aufräumen

Um die erstellten Ressourcen vollständig zu entfernen, gehen wir diesmal den einfachen Weg:

```shell
minikube delete
minikube start
```

Dadurch wird der Cluster komplett gelöscht und neu aufsetzt.