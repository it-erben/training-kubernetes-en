# Konfigurationsdateien mit ConfigMaps ausliefern

Es ist durchaus üblich, kompakte und statische Dateien in ConfigMaps abzulegen und Pods zur Verfügung stellen.
In diesem Beispiel nutzen wir eine ConfigMap, um eine Startseite für einen NGINX-Pod auszuliefern. In der Realität könnte dies eine Seite sein, auf die der Readiness-Check prüft.

## ConfigMap anlegen

Die ConfigMap mit der HTML-Seite sieht wie folgt aus:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-index-config
data:
  index.html: |
    <html>
    <head>
        <title>Willkommen bei NGINX</title>
    </head>
    <body>
        <h1>Hallo, Welt!</h1>
        <p>Dies ist eine benutzerdefinierte Startseite für den NGINX-Server.</p>
    </body>
    </html>
```

Speichere sie in einer Datei ab und wende sie mit kubectl an.
Erstelle nun eine YAML-Datei mit einem Pod, welche obige ConfigMap als Volume mountet und als Startseite von NGINX verfügbar macht. Nimm dazu diesen Mount als Vorlage:

```yaml
volumeMounts:
  - name: nginx-index-volume
    mountPath: /usr/share/nginx/html/index.html
    subPath: index.html
```

Erstelle zuletzt einen NodePort-Service namens "nginx-service" der auf den Pod weiterleitet.
Verwende folgenden Befehl, um einen Tunnel zum Service zu öffnen und zu testen, ob die HTML-Seite erscheint:

```yaml
minikube service nginx-service
```
