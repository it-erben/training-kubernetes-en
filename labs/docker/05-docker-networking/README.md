# Docker Networking

Lege ein Docker Network an und starte zwei Container mit Verbindung zum Network.

```shell
docker network create --driver bridge mein-bridge-netzwerk
docker run -itd --name container-1 --network mein-bridge-netzwerk alpine 
docker run -itd --name container-2 --network mein-bridge-netzwerk alpine
```
Teste die Netzwerkverbindung mit Ping
```shell
docker exec container-1 ping -c 4 container-2
docker exec container-2 ping -c 4 container-1
```
Lösche Container und Netzwerk.
```shell
docker rm -f container-1 container-2
docker network rm mein-bridge-netzwerk
```
