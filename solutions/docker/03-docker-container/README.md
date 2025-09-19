# Lösungen zu den Aufgaben für Docker Container

## Übung 1

```shell
docker pull httpd:latest
docker create --name my-httpd httpd:latest
docker container ls -a
docker start my-httpd
docker ps
docker stop my-httpd
docker rm my-httpd
```

## Übung 2

```shell
docker pull nginx:latest
docker create --name praxisaufgabe nginx
docker start praxisaufgabe
docker exec praxisaufgabe "apt-get" "update"
docker exec praxisaufgabe "apt-get" "install" "nano" "-y"
docker exec -it praxisaufgabe bash
nano
```
