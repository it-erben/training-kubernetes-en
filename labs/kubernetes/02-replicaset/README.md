# ReplicaSet

Dieses Beispiel illustriert, welche Rolle ReplicaSets bei Kubernetes spielen. Die Ressource, die wir uns anschauen, ist in [manifest.yaml](manifest.yaml) definiert.
Bitte auch hier wieder daran denken, mit PowerShell in das korrekte Verzeichnis zu wechseln.

Führe die folgenden Schritte durch, um die Demo zu starten:

Erstelle das ReplicaSet mit dem Manifest:

```sh
kubectl apply -f manifest.yaml
```

Das Manifest enthält ein `ReplicaSet` von drei NGINX-Pods. 
Stelle sicher, dass alle Pods korrekt erstellt wurden:

```sh
kubectl get pods --selector=app=replicaset-demo
```

Dieser Befehlt funktioniert so, wie er ist, weil alle Pods das Label `app=replicaset-demo` tragen. Wenn du dir nicht sicher bist, warum das so ist, schau noch einmal in das Manifest. Dort wirst du das Label im Template finden.

Lösche nun einen Pod:

```sh
kubectl delete pod <POD_NAME>
```

Prüfe die Podliste erneut.

```sh
kubectl get pods --selector=app=replicaset-demo 
```

Das ReplicaSet sollte nun wieder einen dritten Pod angelegt haben. Falls nicht, musst du vielleicht ein paar Sekunden warten.

## Aufräumen
```shell
kubectl delete replicaset.apps/replicaset-demo
```

## Bonus

- [Dokumentation zu ReplicaSets](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
