# Solution for the Docker Networking exercise

```shell
docker network create --driver bridge my-bridge-network
docker run -itd --name container-1 --network my-bridge-network alpine
docker run -itd --name container-2 --network my-bridge-network alpine
docker exec container-1 ping -c 4 container-2
docker exec container-2 ping -c 4 container-1
docker rm -f container-1 container-2
docker network rm my-bridge-network
```
