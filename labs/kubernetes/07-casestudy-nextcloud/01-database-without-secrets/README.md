# Nextcloud Stufe 1: Datenbank

Wir richten als Erstes die Datenbank ein, die Nextcloud zum Betrieb benötigt. 
Schritt 0 ist dabei, einen Namespace anzulegen, in dem wir fortan alle anderen Ressourcen anlegen werden:

```shell
kubectl apply -f namespace.yaml
```

Damit wir fortan nicht in jedem Befehl immer den Namespace mitgeben müssen, in dem wir uns befinden, können wir kubectl den neuen Standard-Namespace mitteilen:

```shell
kubectl config set-context --current --namespace=nextcloud
```

Als Nächstes legen wir die Datenbank an. Sie ist als StatefulSet modelliert und speichert ihre Daten in einem PersistentVolume.

```shell
kubectl apply -f db.yaml
```

Um nachzuvollziehen, was wir angelegt haben, bitte ich euch, mit kubectl alle StatefulSets aufzulisten sowie alle Services. Prüft, ob der Pod für die Datenbank erfolgreich gestartet wurde. Das kann etwas dauern!

Lasst euch mit `kubectl logs` die Logs für den Pod ausgeben. Prüft daraufhin auch, ob der Service für die Datenbank (der übrigens headless ist) existiert. In der nächsten Aufgabe werden wir dann mit PhpMyAdmin prüfen, ob die Datenbank auch wirklich funktioniert.