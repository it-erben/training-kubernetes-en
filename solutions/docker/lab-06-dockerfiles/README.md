# Solution: Dockerfiles

## Task 1: Build the Flask app

```bash
docker build -t my_flask_app .
docker run -d -p 8080:80 --name my_flask_container my_flask_app
curl http://localhost:8080
docker logs my_flask_container
docker rm -f my_flask_container
docker rmi my_flask_app
```

## Task 2: Custom NGINX image

Example Dockerfile:

```Dockerfile
FROM nginx:latest
COPY index.html /usr/share/nginx/html/index.html
```

Example `index.html`:

```html
<!DOCTYPE html>
<html>
  <body><h1>Hello World</h1></body>
</html>
```

Build and run:

```bash
docker build -t my-nginx .
docker run -d -p 9000:80 --name my-nginx my-nginx
curl http://localhost:9000
docker rm -f my-nginx
docker rmi my-nginx
```
