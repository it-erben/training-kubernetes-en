# DaemonSets auf EKS

Wende auf dem in [Modul 1](../01-eks) angelegten Cluster das Manifest [ds.yaml](./ds.yaml) an.
Zeige danach als Erstes, dass auf jeden Node ein Pod des DaemonSets läuft:

```shell
kubectl get pods -o wide
```

Daraufhin kannst du dich mit ssh auf einen der Knoten verbinden und prüfen, ob die Datei angelegt wurde.
