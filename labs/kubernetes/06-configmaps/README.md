# Arbeiten mit ConfigMaps

In dieser Serie von Aufgaben lernen wir den Umgang mit ConfigMaps kennen. Fast alle Konzepte für ConfigMaps lassen sich später auf Secrets übertragen.

## Übung 1: Erstellen einer ConfigMap

Wir erstellen eine ConfigMap mit dem Namen my-config, die zwei Schlüssel-Wert-Paare enthält: `key1: value1` und `key2: value2`.

Wir werden sowohl imperative als auch deklarative Methoden verwenden, um die ConfigMap zu erstellen.

#### Imperative Methode

Der folgende Befehl legt eine ConfigMap mit Namen "my-config" an und enthält zwei Schlüssel-Wert-Kombinationen.
```bash
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2
```

Lasst euch nun den Inhalt der neuen ConfigMap ausgeben:

```shell
kubectl get configmap my-config -o "jsonpath= {.data.key1}"
```

`jsonpath` dient dabei dazu, den Wert des Schlüssels `key1` direkt herauszusuchen und auszugeben. Um genauer zu verstehen, warum `.data.key` übergeben wird, könnt ihr euch einmal den Inhalt ohne `jsonpath` ausgeben lassen:

```shell
kubectl get configmap my-config -o json
```

Ihr werdet sehen, dass die Schlüssel-Wert-Kombinationen im Unterfeld `data` enthalten sind.

Um anschließend die ConfigMap wieder zu löschen:

```shell
kubectl delete configmap my-config
```

#### Deklarative Methode

Die Datei [declarative-config.yaml](declarative-config.yaml) enthält die gleiche ConfigMap, die wir oben angelegt haben, als YAML. Wir können sie direkt mit kubectl anwenden.

```bash
kubectl apply -f declarative-config.yaml
```

Lasst euch nun den Inhalt der neuen ConfigMap ausgeben um zu prüfen, dass das Ergebnis wie erwartet ist:

```shell
kubectl get configmap my-config -o "jsonpath= {.data.key1}"
```

Um die ConfigMap wieder zu löschen:

```bash
kubectl delete configmap my-config
```

## Übung 2: Verwenden einer ConfigMap in einem Pod

Die Datei [config-pod.yaml](config-pod.yaml) enthält die Deklarationen einer ConfigMap sowie einen Pod. Dieser loggt das `env` aus und stoppt danach. Wir können das Ergebnis in den Logs sehen.

```bash
kubectl apply -f config-pod.yaml
```

Überprüfen wir nun die Pod-Logs um zu sehen, ob die Umgebungsvariablen wirklich vorhanden sind:

```bash
kubectl logs config-pod
```

In den Logs seht ihr alle Umgebungsvariablen, die der Pod kennt. Unter anderem sollten auch `key1` und `key2` enthalten sein. 

Aufräumen:

```bash
kubectl delete configmap my-config
```

## Übung 3: Mappen von ConfigMap-Werten auf Volumen

Die Datei [volume-pod.yaml](volume-pod.yaml) enthält eine ConfigMap, die per Volume in einen Pod gemountet wird. Wie im vorletzten Beispiel wird das Ergebnis geloggt, aber der Container wartet einige Zeit, bis er stoppt. Wir können ihn also mit exec untersuchen.

Anwenden der Datei:

```bash
kubectl apply -f volume-pod.yaml
```

Wir prüfen nun, ob die Dateien erfolgreich in den Pod gemountet wurden:

```bash
kubectl exec -it volume-pod -- ls /etc/config 
```
```bash
kubectl exec -it volume-pod -- cat /etc/config/key1
```

Im ersten Fall seht ihr alle Dateien, die angelegt wurden im Rahmen des Mountens. Der zweite Befehl gibt mit `cat` den Inhalt der Datei `key1` aus, welche den ersten Konfigurationswert enthält.

Haltet jetzt noch einmal einen moment inne und führt euch vor Augen, dass Kubernetes dem Pod für jede Schlüssel-Wert-Kombination in der ConfigMap eine Datei zur Verfügung stellt. Die Dateien enthalten jeweils die in der ConfigMap genannten Werte.

Aufräumen:
```shell
kubectl delete configmap/my-config
kubectl delete pod/volume-pod
```

### Bonus:

- [https://kubernetes.io/docs/concepts/configuration/configmap/](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [https://kubernetes.io/docs/concepts/configuration/secret/](https://kubernetes.io/docs/concepts/configuration/secret/)