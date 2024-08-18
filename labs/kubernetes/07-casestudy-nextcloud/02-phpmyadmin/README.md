# Nextcloud Stufe 2: PhpMyAdmin

Aktuell ist die Datenbank nur im Cluster per Headless Service erreichbar. Das ist im Produktivbetrieb auch durchaus _best practice_. Da wir aber testen wollen, ob die Datenbank auch funktioniert, setzen wir PhpMyAdmin ein.
In diesem Verzeichnis liegt ein Manifest, dass PhpMyAdmin sowie einen NodePort-Service einrichtet, mit dem wir uns aus unserem RDP-Server heraus mit der Webkonsole verbinden können.

```shell
kubectl apply -f pma.yaml
```
 
Prüft nun mit kubectl, ob Deployment und Service erfolgreich angelegt wurden.
Tunnelt euch nun zu PhpMyAdmin, indem ihr 

```shell
minikube service phpmyadmin -n nextcloud
``` 
ausführt. Im Browser solltet ihr nun PhpMyAdmin sehen, der mit der Datenbank verbunden ist.