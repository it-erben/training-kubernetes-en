# Lösungen für die Aufgaben zu Docker Images

## Übung 1

```shell
docker images
docker inspect python:3
docker inspect python:3 --format "{{.Size}}"
docker inspect python:3 --format "{{.Os}}"
docker inspect python:3 --format "{{.Created}}"
docker inspect python:3 --format "{{.Config.Env}}"
```

## Übung 2

```shell
docker pull node:latest
docker image tag node:latest my-node
docker image inspect node:latest --format "{{ .RepoTags }}"
```

```shell
docker image rm my-node:latest
docker image rm node:latest
```
