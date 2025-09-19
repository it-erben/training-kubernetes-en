# Lösung zu der Aufgabe zu Docker Volumes

```shell
docker run -it --rm --mount type=bind,source="${PWD}",target=/tmp/scripts python:3 bash
```
