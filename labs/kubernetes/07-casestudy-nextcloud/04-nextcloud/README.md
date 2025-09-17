# Nextcloud

Die letzte und wichtigste Komponente, die noch fehlt, ist Nextcloud selbst.

In [nextcloud.yaml](nextcloud.yaml) habe ich euch ein vorgefertigtes Deployment bereitgestellt.
Aber da ihr jetzt schon etwas fortgeschritten seid, fehlt noch etwas! Das Deployment verwendet nämlich kein PersistentVolume. Nach einem Update wären alle Daten weg!

Wir müssen uns also darum kümmern, ein PersistentVolume anzufragen und zu mounten.
Als Erstes braucht ihr einen PersistentVolumeClaim:
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nextcloud-pvc
  namespace: nextcloud
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

Baut nun an richtiger Stelle im Manifest den Claim ein:

```yaml
volumes:
  - name: nextcloud-data
    persistentVolumeClaim:
      claimName: nextcloud-pvc
```

Das entstehende Volume müsst ihr schließlich noch mounten:

```yaml
volumeMounts:
  - name: nextcloud-data
    mountPath: /var/www/html
```

Wo genau diese Schnipsel eingefügt werden müssen, werdet ihr selbst herausfinden. Dabei kann euch die Dokumentation helfen – oder die Aufgabe zu Volumes von gestern.

Wenn ihr fertig seid, fehlt außerdem noch ein Service, der Nextcloud nach außen verfügbar macht. Nehmt euch dazu den Service von "PhpMyAdmin" als Vorlage und passt die Namen sowie Labels an, sodass sie zum Nextcloud-Deployment passen.

Wenn alles fertig ist, könnt ihr mit kubectl die Datei anwenden und danach mit minikube einen Tunnel zu eurem Service aufbauen, um Nextcloud zu testen.

Viel Erfolg!
