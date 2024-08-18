# Dockerfile Cheat-Sheet

Ein Dockerfile ist eine Textdatei, die Anweisungen zum Erstellen eines Docker-Images enthält. Hier sind die wichtigsten Anweisungen und Best Practices für die Erstellung eines Dockerfiles.

## Dockerfile-Anweisungen

### FROM

* `FROM <image>:<tag>`: Gibt das Basis-Image an, von dem das neue Image erstellt werden soll. Der Tag ist optional und standardmäßig auf `latest` gesetzt.

Beispiel:

```Dockerfile
FROM ubuntu:20.04
```

### RUN

* `RUN <command>`: Führt einen Befehl aus und erstellt dabei eine neue Ebene im Image. Wird häufig verwendet, um Softwarepakete zu installieren.

Beispiel:

```Dockerfile
RUN apt-get update && apt-get install -y curl
```

### CMD

* `CMD ["executable", "param1", "param2"]`: Gibt den Standardbefehl an, der ausgeführt wird, wenn der Container gestartet wird. Es kann nur eine `CMD`-Anweisung im Dockerfile geben. Wenn mehrere angegeben sind, wird nur die letzte verwendet.

Beispiel:

```Dockerfile
CMD ["echo", "Hello, World!"]
```

### ENTRYPOINT

* `ENTRYPOINT ["executable", "param1", "param2"]`: Gibt den ausführbaren Befehl an, der beim Start des Containers immer ausgeführt wird. Im Gegensatz zu `CMD` können die Parameter des `ENTRYPOINT`-Befehls durch zusätzliche Argumente beim Start des Containers überschrieben werden.

Beispiel:

```Dockerfile
ENTRYPOINT ["echo"]
CMD ["Hello, World!"]
```

### COPY

* `COPY <src> <dest>`: Kopiert Dateien oder Verzeichnisse vom lokalen Host-System in das Image.

Beispiel:

```Dockerfile
COPY ./app /app
```

### ADD

* `ADD <src> <dest>`: Ähnlich wie `COPY`, aber kann auch URLs als Quelle verwenden und TAR-Archive automatisch entpacken.

Beispiel:

```Dockerfile
ADD https://example.com/file.tar.gz /app
```

### WORKDIR

* `WORKDIR <path>`: Setzt das Arbeitsverzeichnis für nachfolgende Anweisungen wie `RUN`, `CMD`, `ENTRYPOINT`, `COPY` und `ADD`.

Beispiel:

```Dockerfile
WORKDIR /app
```

### ENV

* `ENV <key>=<value>`: Setzt eine Umgebungsvariable im Image.

Beispiel:

```Dockerfile
ENV NODE_ENV=production
```

### EXPOSE

* `EXPOSE <port>`: Gibt an, dass der Container auf dem angegebenen Port lauscht.

Beispiel:

```Dockerfile
EXPOSE 8080
```

### VOLUME

* `VOLUME ["/path/to/volume"]`: Erstellt ein Volume, das von Containern verwendet werden kann, um Daten zu speichern oder gemeinsam zu nutzen.

Beispiel:

```Dockerfile
VOLUME ["/data"]
```
Best Practices
- Verwende kleine Basis-Images, um die Größe des resultierenden Images zu reduzieren.
- Fasse mehrere RUN-Anweisungen zusammen, um die Anzahl der erstellten Ebenen zu reduzieren.
- Verwende `.dockerignore`, um unnötige Dateien aus dem Build-Kontext auszuschließen.
- Verwende COPY anstelle von ADD, es sei denn, du benötigst die erweiterten Funktionen von ADD.
- Setze Umgebungsvariablen sparsam ein und vermeide die Speicherung sensibler Informationen in ihnen.
