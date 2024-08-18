# Kubectl Cheat Sheet für Einsteiger

Kubectl ist ein Befehlszeilen-Tool zur Verwaltung von Kubernetes-Clustern. Hier ist ein grundlegendes Cheat Sheet für Einsteiger:

## Cluster-Informationen

- `kubectl version` - Zeige die Version von kubectl und dem Cluster
- `kubectl cluster-info` - Zeige Cluster-Informationen
- `kubectl get nodes` - Liste alle Knoten im Cluster auf

## Manifeste
- `kubectl apply -f <Dateiname>` Manifest anwenden

## Namespaces

- `kubectl get namespaces` - Liste alle Namespaces auf
- `kubectl create namespace <namespace>` - Erstelle einen neuen Namespace
- `kubectl delete namespace <namespace>` - Lösche einen Namespace

## Deployments

- `kubectl get deployments` - Liste alle Deployments auf
- `kubectl get deployment -w` - Liste alle Deployments auf und warte auf Aktualisierungen
- `kubectl get deployment <deployment-name>` Gibt Details über ein Deployment aus
- `kubectl get deployment <deployment-name> -o yaml` Gibt vollständige Details über ein Deployment aus
- `kubectl delete deployment <deployment-name>` - Lösche ein Deployment
- `kubectl scale deployment <deployment-name> --replicas=<number>` - Skaliere ein Deployment

## Pods

- `kubectl get pods` - Liste alle Pods auf
- `kubectl get pods -o wide` - Liste alle Pods mit zusätzlichen Details auf
- `kubectl get pods -w` - Liste alle Pods auf und warte auf Aktualisierungen
- `kubectl get pod <pod-name>` - Gibt ein paar Details zu einem Pod aus
- `kubectl get pod <pod-name> -o yaml` - Gibt viele Details zu einem Pod aus
- `kubectl describe pod <pod-name>` - Zeige Details eines Pods
- `kubectl delete pod <pod-name>` - Lösche einen Pod

## Services

- `kubectl get services` - Liste alle Services auf
- `kubectl delete service <service-name>` - Lösche einen Service

## Logs und Debugging

- `kubectl logs <pod-name>` - Zeige Logs eines Pods
- `kubectl exec -it <pod-name> -- <command>` - Führe einen Befehl in einem Pod aus
- `kubectl cp <pod-name>:<src-path> <dst-path>` - Kopiere Dateien zwischen Pod und lokalem System

## ConfigMaps und Secrets

- `kubectl get configmaps` - Liste alle ConfigMaps auf
- `kubectl create configmap <configmap-name> --from-file=<file-path>` - Erstelle eine ConfigMap aus einer Datei
- `kubectl delete configmap <configmap-name>` - Lösche eine ConfigMap
- `kubectl get secrets` - Liste alle Secrets auf
- `kubectl create secret generic <secret-name> --from-file=<file-path>` - Erstelle ein Secret aus einer Datei
- `kubectl delete secret <secret-name>` - Lösche ein Secret

## Kontext und Konfiguration

- `kubectl config view` - Zeige die aktuelle kubectl-Konfiguration
- `kubectl config use-context <context-name>` - Wechsle den aktuellen Kontext
- `kubectl config set-context <context-name> --namespace=<namespace>` - Setze den Namespace für einen Kontext

Dieses Cheat Sheet bietet eine grundlegende Übersicht über die wichtigsten kubectl-Befehle für Einsteiger. Für weitere Informationen und Befehle besuchen Sie die offizielle [Kubernetes-Dokumentation](https://kubernetes.io/docs/reference/kubectl/overview/).