# Secrets für die Datenbank

Euch ist vielleicht schon aufgefallen, dass wir Datenbanknutzer und Passwort im Manifest für PhpMyAdmin einfach kopiert haben aus dem Manifest für die Datenbank. Das ist unschön – und auch unsicher. Wir wollen nun die Zugangsdaten in ein Kubernetes-Secret auslagern.

Dazu liefere ich euch diesmal kein fertiges Manifest. Aber hier ist eine Anleitung, wie ihr vorgehen müsst, am Beispiel des Datenbank-StatefulSet:

Der Abschnitt mit den Umgebungsvariablen, den wir ersetzen wollen, sieht wie folgt aus:

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

Für diese Einträge brauchen wir im ersten Schritt ein Secret.

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: nextcloud-db-secret
  namespace: nextcloud
type: Opaque
stringData:
  MYSQL_USER: "nextcloud"
  MYSQL_ROOT_PASSWORD: "mysecretpassword"
  MYSQL_PASSWORD: "nextcloudpassword"
  MYSQL_DATABASE: "nextcloud"
```
Dieses Manifest legt ihr euch am besten in eine Datei `secret.yaml` an, die ihr später anwenden werdet.
Das Secret müssen wir nun in das Manifest `db.yaml` sowie in `pma.yaml` referenzieren.
Für das StatefulSet der Datenbank sieht dies wie Folgt aus:

```yaml
env:
- name: MYSQL_ROOT_PASSWORD
  valueFrom:
    secretKeyRef:
      name: nextcloud-db-secret
      key: MYSQL_ROOT_PASSWORD
- name: MYSQL_USER
  valueFrom:
    secretKeyRef:
      name: nextcloud-db-secret
      key: MYSQL_USER
- name: MYSQL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: nextcloud-db-secret
      key: MYSQL_PASSWORD
- name: MYSQL_DATABASE
  valueFrom:
    secretKeyRef:
      name: nextcloud-db-secret
      key: MYSQL_DATABASE
```
Das Muster ist immer das Gleiche. Der `name` der Umgebungsvariable bleibt so wie vorher, aber der Wert kommt jetzt aus dem Secret.

Für PhpMyAdmin in der `pma.yaml` müssen wir es ein wenig anders machen, weil die Umgebungsvariablen anders heißen:
```yaml
env:
- name: PMA_USER
  valueFrom:
    secretKeyRef:
      name: nextcloud-db-secret
      key: MYSQL_USER
- name: PMA_PASSWORD
  valueFrom:
    secretKeyRef:
      name: nextcloud-db-secret
      key: MYSQL_PASSWORD
- name: PMA_HOST
  value: nextcloud-db
- name: PMA_PORT
  value: "3306"
```

Wenn ihr fertig seid, könnt ihr die beiden Dateien mit apply anwenden:

```shell
kubectl apply -f secret.yaml
kubectl apply -f pma.yaml
kubectl apply -f db.yaml
```

Baut zuletzt den Tunnel zu phpmyadmin wieder auf und schaut, ob alles noch funktioniert:

```shell
minikube service phpmyadmin -n nextcloud
```