# Solutions for the Docker Container exercises

## Exercise 1

```shell
docker pull httpd:latest
docker create --name my-httpd httpd:latest
docker container ls -a
docker start my-httpd
docker ps
docker stop my-httpd
docker rm my-httpd
```

## Exercise 2

```shell
docker pull nginx:latest
docker create --name practice-task nginx
docker start practice-task
docker exec practice-task "apt-get" "update"
docker exec practice-task "apt-get" "install" "nano" "-y"
docker exec -it practice-task bash
nano
```
