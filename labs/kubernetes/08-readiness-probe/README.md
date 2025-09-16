# Readiness Probes mit httpGet

In dieser Übungsaufgabe zeige ich euch, wie ihr Readiness-Probes einsetzen könnt, um eure Anwendung zu überwachen.

## Vorbereitung: Deployment aufsetzen

In [manifest.yaml](./manifest.yaml) findet ihr ein Deployment mit NGINX-Containern. 
Es enthält bewusst einen Fehler in der Readiness-Probe.

Wendet als Erstes das Manifest an:

```shell
kubectl apply -f manifest.yaml
```

Prüft danach, ob die Pods des Deployments laufen:

```shell
k get po --selector=app=readiness-check-demo
#NAME                                           READY   STATUS    RESTARTS   AGE
#readiness-check-demo-deploy-7ff9c8f684-dv9t7   0/1     Running   0          102s
#readiness-check-demo-deploy-7ff9c8f684-fg2qw   0/1     Running   0          102s
#readiness-check-demo-deploy-7ff9c8f684-r4qkr   0/1     Running   0          102s
```

Die Pods laufen zwar, sind aber nicht Ready. Dementsprechend werden sie nicht vom Service verwendet.
Das könnt ihr testen, indem ihr einen Debug-Pod startet:

```shell
kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh
```

Ihr befindet euch nun im Terminal eines Containers mit Busybox. Nutzt nslookup um zu prüfen, ob der Service grundsätzlich per DNS aufgelöst werden kann:

```shell
nslookup readiness-check-demo-svc.default.svc.cluster.local

# Server:		10.96.0.10
# Address:	10.96.0.10:53

# Name:	readiness-check-demo-svc.default.svc.cluster.local
# Address: 10.103.46.232
```

Versucht daraufhin, die letztgenannte IP-Adresse per wget aufzurufen:
```shell
wget -O- readiness-check-demo-svc.default.svc.cluster.local
# Connecting to readiness-check-demo-svc.default.svc.cluster.local (10.103.46.232:80)
# wget: can't connect to remote host (10.103.46.232): Connection refused
```

Da keiner der Pods ready ist, kann keine Verbindung aufgebaut werden.

## Aufgabe

Behebt die ReadinessProbe in [manifest.yaml](./manifest.yaml).
Wendet das Manifest danach an und prüft mit dem Busybox-Testpod, ob ihr euch per wget mit dem Service verbinden könnt.
