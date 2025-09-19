# Lösung zur Übungsaufgabe zu Docker Networking

```shell
docker network create --driver bridge mein-bridge-netzwerk
docker run -itd --name container-1 --network mein-bridge-netzwerk alpine
docker run -itd --name container-2 --network mein-bridge-netzwerk alpine
docker exec container-1 ping -c 4 container-2
docker exec container-2 ping -c 4 container-1
docker rm -f container-1 container-2
docker network rm mein-bridge-netzwerk
```
