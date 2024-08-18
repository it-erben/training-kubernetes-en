# NGINX StatefulSet mit Headless Service

Das [Manifest](manifest.yaml) erzeugt ein `StatefulSet` mit drei Replicas eines `nginx`-Pods, der den Container-Port 80 belegt. Außerdem wird ein `Service` definiert, der im sogenannten Headless-Modus läuft. Das bedeutet, dass er keine ClusterIP erhält (`clusterIP: None`). Wir schauen uns nun an, was genau dies bedeutet.

## Manifest anwenden
Zuerst legen wir die benötigten Ressourcen an und prüfen, ob sie korrekt erzeugt wurden.
```shell
kubectl apply -f manifest.yaml
```
Danach schauen wir, ob Service und Pods erfolgreich angelegt bzw. gestartet wurden.
```shell
kubectl get service nginx-headless
```
```shell
kubectl get pod --selector=app=nginx
```

## DNS untersuchen mit busybox

Wir verwenden `kubectl debug`, um einen Hilfscontainer zu starten. Wir untersuchen den ersten Pod des StatefulSet `nginx-0` und benutzen [busybox](https://github.com/mirror/busybox), ein Image zum Debuggen von Netzwerkproblemen.

```shell
kubectl debug nginx-0 -it --image=busybox
```

Der DNS-Name des Services, den wir angelegt haben, ist 
`nginx-headless.default.svc.cluster.local` und wir werden sehen, dass dieser auf drei IP-Adressen verweist: eine pro Pod. Der Service selbst hat _keine_ ClusterIP! Nur die Pods haben eine IP, wie sie es immer haben (zumindest fast...).

```shell
nslookup nginx-headless.default.svc.cluster.local
```
```shell
Name:   nginx-headless.default.svc.cluster.local
Address: 10.244.0.65
Name:   nginx-headless.default.svc.cluster.local
Address: 10.244.0.66
Name:   nginx-headless.default.svc.cluster.local
Address: 10.244.0.64
```

Darüber hinaus legt der Headless Service einen DNS-Namen pro Pod an mit einem laufenden Index:

```
<STATEFULSETNAME>-<INDEX>.<SERVICENAME>.<NAMESPACE>.svc.cluster.local
```
also z.B.
```
nginx-0.nginx-headless.default.svc.cluster.local
```

Und das können wir auch mit nslookup belegen


```shell
nslookup nginx-0.nginx-headless.default.svc.cluster.local
```
```Server:         10.96.0.10
Address:        10.96.0.10:53


Name:   nginx-0.nginx-headless.default.svc.cluster.local
Address: 10.244.0.64 # hier ist die Adresse des Pods!
```

## Aufräumen
```shell
kubectl delete statefulset.apps/nginx
kubectl delete service/nginx-headless
```

## Bonus
-[Dokumentation zu StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
