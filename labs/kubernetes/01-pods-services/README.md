# NGINX Pods und Services des Typs ClusterIP

Das [Manifest](manifest.yaml) erzeugt zwei Pods und einen Service. Da kein Typ angegeben ist, fällt er auf den Default zurück: `ClusterIP`. Dieser Service Type legt eine statische IP-Adresse im Cluster an, unter der der Service erreichbar ist. Zusätzlich gibt es noch einen DNS-Namen, der auf den Service zeigt. Dies werden wir weiter unten sehen.

## Manifest anwenden
Zuerst legen wir die benötigten Ressourcen an und prüfen, ob sie korrekt erzeugt wurden.
Bitte beachte, dass du dazu mit PowerShell im korrekten Verzeichnis sein musst – nämlich in dem, in dem sich die manifest.yaml befindet.
```shell
kubectl apply -f manifest.yaml
```

Daraufhin kannst du mit `kubectl get pod` die gerade angelegten Pods finden. Das `--selector`-Argument filtert dir die Pods heraus, die wir gerade angelegt haben.

```shell
kubectl get pod --selector=app=nginx-pod-demo
```

## DNS untersuchen mit busybox

Wir wollen nun prüfen, ob wirklich ein Service angelegt wurde, der im Cluster adressiert werden kann.

Dazu verwenden wir `kubectl debug`, um einen Hilfscontainer zu starten. Mit diesem praktischen Befehl startet Kubernetes einen Container nur zu dem Zweck, einen anderen Container zu untersuchen.
Wir untersuchen den ersten Pod `nginx-pod-1` und benutzen [busybox](https://github.com/mirror/busybox), ein Image zum Debuggen von Netzwerkproblemen.

```shell
kubectl debug nginx-pod-1 -it --image=busybox
```
Der obige Befehl startet eine Sitzung mit einem neuen Container des images `busybox` mit dem Zweck, den Pod `nginx-pod-1` zu untersuchen.
Als Nächstes verwenden wir den Linux-Befehl `nslookup` um zu schauen, welche IP-Adresse hinter dem DNS-Namen des Services steht, den wir angelegt haben. 
Zur Erinnerung: Services haben das Namensschema

`<ServiceName>.<Namespace>.svc.cluster.local`

und da alle Ressourcen standardmäßig im `default`-Namespace landen wenn nicht anders angegeben, befindet sich auch unser Service dort. Daraus resultiert der DNS-Name

`nginx-pod-demo-svc.default.svc.cluster.local`

```shell
nslookup nginx-pod-demo-svc.default.svc.cluster.local
```

nslookup gibt uns eine IP-Adresse zurück, wenn wir alles richtig gemacht haben:
```shell
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   nginx-pod-demo-svc.default.svc.cluster.local
Address: 10.109.154.35
```
Die IP ist dabei der _letzte_ Eintrag. Die ersten beiden IPs oben sind die IPs des DNS-Servers.
Die Service-IP können wir nun nutzen, um mit dem Tool `wget` eine Anfrage zu starten:

`wget -q -O- <IP>`

Tragt bitte die IP ein, die ihr oben ermittelt habt. Der Befehl sollte erfolgreich sein.

## Aufräumen
```shell
kubectl delete service/nginx-pod-demo-svc
kubectl delete pod/nginx-pod-1
kubectl delete pod/nginx-pod-2
```

## Bonus
Wenn du schon fertig bist, sind hier noch Zusatzressourcen:

- [Dokumentation zu Pods und Pod Lifecycles in Kubernetes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Dokumentation zu Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)

