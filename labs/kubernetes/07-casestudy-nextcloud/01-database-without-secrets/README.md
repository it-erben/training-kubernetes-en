# Nextcloud Stufe 1: Datenbank

Wir richten als Erstes die Datenbank ein, die Nextcloud zum Betrieb benötigt.
Schritt 0 ist dabei, einen Namespace namens "nextcloud" anzulegen. Benutze hierfür `kubectl`.

Damit wir fortan nicht in jedem Befehl immer den Namespace mitgeben müssen, in dem wir uns befinden, können wir kubectl den neuen Standard-Namespace mitteilen:

```shell
kubectl config set-context --current --namespace=nextcloud
```

Deine Aufgabe ist es nun, ein Kubernetes-Manifest zu erstellen, das eine MariaDB-Datenbank bereitstellt. Das Manifest soll aus zwei Teilen bestehen: einem StatefulSet, das die MariaDB-Datenbank konfiguriert und bereitstellt, und einem Service, der den Zugriff auf die Datenbank ermöglicht.

## StatefulSet erstellen

- Definiere das StatefulSet mit dem Namen `nextcloud-db` im Namespace `nextcloud`.
- Setze die Anzahl der Replikate (replicas) auf `1`, da wir nur eine Instanz der Datenbank benötigen.
- Lege ein Container-Template für MariaDB an, das das neueste MariaDB-Image (`mariadb:latest`) verwendet.
- Füge Umgebungsvariablen hinzu, um die Datenbank zu konfigurieren:
  ```yaml
  env:
    - name: MYSQL_ROOT_PASSWORD
      value: "mysecretpassword"
    - name: MYSQL_DATABASE
      value: "nextcloud"
    - name: MYSQL_USER
      value: "nextcloud"
    - name: MYSQL_PASSWORD
      value: "nextcloudpassword"
  ```

  - Definiere einen Volume-Mount, der sicherstellt, dass die Datenbankdaten im Verzeichnis `/var/lib/mysql` gespeichert werden.
  - Erstelle ein VolumeClaimTemplate, das ein Persistent Volume mit einer Größe von `10Gi` anfordert und sicherstellt, dass es nur von einem Knoten gleichzeitig beschrieben werden kann (AccessMode: `ReadWriteOnce`).
  ```yaml
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
  ```

## Service erstellen

- Definiere einen Service mit dem Namen `nextcloud-db` im Namespace `nextcloud`.
- Setze die `clusterIP` auf `None`, sodass jeder Pod im StatefulSet einen eigenen DNS-Namen erhält.
- Lege einen Port fest, über den der Datenbank-Service erreichbar ist (Port `3306`).

## Manifest fertigstellen

Achte darauf, dass das Manifest syntaktisch korrekt ist und den oben genannten Anforderungen entspricht.

Das Ergebnis sollte ein YAML-Dokument sein, das die Konfiguration für ein StatefulSet und einen dazugehörigen Service beschreibt.
Wende das Manifest an und prüfe anschließend, ob das StatefulSet wie erwartet läuft.

## Ergebnis prüfen

Starte einen Debug-Pod und prüfe, ob der Service erreichbar ist und eine IP für den Pod zurückliefert.

```yaml
kubectl run -i --tty busybox --image=busybox --restart=Never -- sh
#/ nslookup nextcloud-db.nextcloud.svc.cluster.local
```

Viel Erfolg!
