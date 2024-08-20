# Nextcloud Stufe 2: PhpMyAdmin

Aktuell ist die Datenbank nur im Cluster per Headless Service erreichbar. Das ist im Produktivbetrieb auch durchaus _best practice_. Da wir aber testen wollen, ob die Datenbank auch funktioniert, setzen wir PhpMyAdmin ein.

Deine Aufgabe ist es, ein Kubernetes-Manifest zu erstellen, das eine Instanz von phpMyAdmin bereitstellt. phpMyAdmin wird verwendet, um die MariaDB-Datenbank für eine Nextcloud-Instanz zu verwalten. Das Manifest soll aus zwei Teilen bestehen: einem Deployment, das die phpMyAdmin-Anwendung konfiguriert und bereitstellt, und einem Service, der den Zugriff auf phpMyAdmin über einen bestimmten Port ermöglicht.

## Deployment erstellen
- Definiere ein Deployment mit dem Namen `phpmyadmin` im Namespace `nextcloud`.
- Setze die Anzahl der Replikate (replicas) auf `1`, da wir nur eine Instanz von phpMyAdmin benötigen.
- Erstelle ein Container-Template für phpMyAdmin, das das Image `phpmyadmin:5.2.1` verwendet.
- Lege den Container-Port auf `80` fest, da phpMyAdmin über diesen Port erreichbar sein soll.
- Füge Umgebungsvariablen hinzu:
```yaml
env:
- name: PMA_HOST
  value: nextcloud-db
- name: PMA_PORT
  value: "3306"
- name: PMA_USER
  value: "nextcloud"
- name: PMA_PASSWORD
  value: "nextcloudpassword"
```
- Definiere Ressourcenanforderungen und -limits für den phpMyAdmin-Container:
  - **Limits**:
      - CPU: `500m` (500 Millikernprozessoren)
      - Speicher: `512Mi` (512 Megabyte)
  - **Requests**:
      - CPU: `100m` (100 Millikernprozessoren)
      - Speicher: `100Mi` (100 Megabyte)

## Service erstellen:**
- Definiere einen Service mit dem Namen `phpmyadmin` im Namespace `nextcloud`.
- Setze den Port auf `80`, um den phpMyAdmin-Service auf diesem Port verfügbar zu machen.
- Setze `targetPort` auf `80`, damit der Service den Container-Port korrekt weiterleitet.
- Definiere `nodePort` auf `30000`, damit der Service von außerhalb des Clusters über diesen Port erreichbar ist.
- Setze den Servicetyp auf `NodePort`, um den Zugriff auf phpMyAdmin von außerhalb des Kubernetes-Clusters zu ermöglichen.

Wende das Manifest an.
Prüft nun mit kubectl, ob Deployment und Service erfolgreich angelegt wurden.
Tunnelt euch nun zu PhpMyAdmin, indem ihr 

```shell
minikube service phpmyadmin -n nextcloud
``` 
ausführt. Im Browser solltet ihr nun PhpMyAdmin sehen, der mit der Datenbank verbunden ist.
