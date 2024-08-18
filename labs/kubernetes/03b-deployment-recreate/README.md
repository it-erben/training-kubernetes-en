# Deployments mit Recreate-Rollout

Das [Manifest](manifest.yaml) enthält ein Deployment, das dem aus der letzten Aufgabe sehr ähnlich ist. Allerdings ist nun konfiguriert, dass das Deployment nicht im Modus `RollingUpdate` ausgerollt werden soll, sondern im Modus `Recreate`. Schauen wir uns an, was das bedeutet.

## Beispiel ausführen

Erstelle das Deployment.

```bash
kubectl apply -f manifest.yaml
```

Überprüfe den Status des Deployments:

```bash
kubectl rollout status deployment/deployment-recreate-demo
```

Der Rollout sollte bald erfolgreich sein. Danach kannst du dir alle Pods auflisten lassen mit dem Label, welches in der Pod Template-Spec des Deployments angegeben ist:

```shell
kubectl get pod --selector=app=deployment-recreate-demo
```

Löse nun ein Update aus durch eine neue Imageversion, z.B. `nginx:alpine3.18`.

```bash
kubectl set image deployment/deployment-recreate-demo nginx=nginx:alpine3.18
```

Überwache das Rolling-Update. 

```bash
kubectl rollout status deployment/deployment-recreate-demo
```

Es fällt sofort auf, dass das Rollout sehr viel schneller geht als beim Rolling Update. Das Deployment geht im Modus `Recreate` nämlich nicht Pod für Pod vor, sondern löscht alle auf einmal und legt sie neu an. 

## Aufräumen
```shell
kubectl delete deployment.apps/deployment-recreate-demo
```

## Bonus

- [Dokumentation zu Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
