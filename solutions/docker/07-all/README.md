# Beispiellösung Abschlussübung

## Dockerfile

```Dockerfile
FROM node:18-slim
WORKDIR /app
COPY app.js .
EXPOSE 8080
CMD ["node", "app.js"]
```

## Skript

```bash
# Image bauen
docker build -t final-app .

# Volume anlegen
docker volume create final-data

# Netzwerk anlegen
docker network create final-net

# Container starten mit Port-Mapping, Volume und Netzwerk
docker run -d --name final-app \
  -p 8080:8080 \
  -v final-data:/app/data \
  --network final-net \
  final-app

# Zweiten Container im gleichen Netzwerk starten
docker run -it --rm --network final-net --name helper alpine sh

# Aufräumen
docker stop final-app
docker rm final-app
docker rmi final-app
docker volume rm final-data
docker network rm final-net
```
