# Autoscaling mit dem HPA

In diesem Beispiel führen wir ein neues Konzept und eine neue Ressource ein:
Autoscaling mit dem `HorizontalPodAutoscaler`, auch HPA genannt. Damit der HPA seine Arbeit verrichten kann, müssen wir als Erstes in Minikube den Metrics-Server aktivieren:

```shell
minikube addons enable metrics-server
```

Lege danach folgende Ressourcen an:

- Ein `ReplicaSet` mir 3 Replikas. Als Image verwendest du bitte `nginx:latest`. Beachte, dass die Port-Einstellung korrekt ist.
- Einen dazu passenden `Service` vom Typ `ClusterIP`

Füge danach in den nginx-Container im `ReplicaSet` folgenden Eintrag ein. Die Kommentare oben und unten dienen dir nur als Orientierung, wo dieses Schnippsel hingehört.

```yaml
# image: nginx:latest
  resources:
    requests:
      cpu: "100m"
    limits:
      cpu: "100m"
# ports: ...
```

Wendet danach euer Manifest mit dem HPA mit `kubectl apply` an.

Für Autoscaling brauchen nun noch die HPA-Ressource. Legt dazu eine neue Datei an und fügt diese Ressource ein:

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: ReplicaSet
    name: # Hier den Namen eintragen
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 30
```

Fügt den korrekten Namen eures `ReplicaSet` ein!

Wendet danach euer Manifest mit dem HPA mit `kubectl apply` an.

Ihr könnt erkennen, dass der HPA direkt mit `scaleTargetRef` an das Replikaset gebunden wird. Hier werden ausnahmsweise mal keine Labels eingesetzt.
Mit `targetCPUUtilizationPercentage` wird definiert, dass die CPU-Auslastung im Mittel bei 30% liegen soll.

Es kann nun etwas dauern, bis der HPA korrekt seine Arbeit verrichtet – abhängig davon, wie lange der Metrics Server braucht, um CPU-Metriken zu sammeln.

Um zu prüfen, ob der HPA bereit ist, führt den folgenden Befehl aus:
```shell
kubectl get hpa
```
Es ist wichtig, dass bei TARGETS nicht "unknown" steht, sondern zwei Prozentzahlen:
```shell
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   ReplicaSet/nginx-replicaset   0%/30%    3         10        3          2m24s
```
Wenn dies noch nicht der Fall ist, dann ist der Metrics-Server noch nicht bereit. Das kann tatsächlich mehrere Minuten dauern.

## Lasttest

Wir wollen nun die Probe aufs Exempel machen und prüfen, ob das Autoscaling wirklich funktioniert. Am besten macht ihr dafür nun zwei Powershell-Sitzungen auf:

- In der ersten Sitzung führt ihr den Befehl `kubectl get hpa -w` aus. Dadurch könnt ihr kontinuierlich sehen, wie viele Pods laufen.
- Im zweiten Fenster lassen wir einen Lasttest laufen: 

```shell
kubectl run -i --tty loadtest --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.0001; do wget -q -O- http://nginx-service; done"
```

Beobachtet nun im ersten Fenster die Statistik des HPA. Mit der Zeit wird die CPU-Auslastung steigen und irgendwann auch die Replica-Zahl steigen.

```shell
~ ❯❯❯ k get hpa -w
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   ReplicaSet/nginx-replicaset   1%/50%    1         10        1          12m
nginx-hpa   ReplicaSet/nginx-replicaset   17%/50%   1         10        1          13m
nginx-hpa   ReplicaSet/nginx-replicaset   41%/50%   1         10        1          14m
nginx-hpa   ReplicaSet/nginx-replicaset   40%/50%   1         10        1          15m
nginx-hpa   ReplicaSet/nginx-replicaset   42%/50%   1         10        1          16m
nginx-hpa   ReplicaSet/nginx-replicaset   66%/50%   1         10        1          17m
nginx-hpa   ReplicaSet/nginx-replicaset   66%/50%   1         10        2          18m
```
