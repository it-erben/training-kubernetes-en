# Lab 06: Dockerfiles

## Task 1

In this task we create a small Flask application, package it into a Docker image and start a
container from it.

First, build the image using the files provided in this directory.

**`Dockerfile`:**

```dockerfile
FROM python:3.14
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

ENV FLASK_ENV=production

EXPOSE 80

CMD ["python", "app.py"]
```

**`app.py`:**

```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, welcome to the Docker Flask application!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
```

**`requirements.txt`:**

```txt
Flask==3.1.2
```

**`.dockerignore`:**

```txt
README.md
```

```shell
docker build -t my_flask_app .
```

Start a container from it:

```shell
docker run -d -p 8080:80 --name my_flask_container my_flask_app
```

Open a browser at [](http://localhost:8080) and check whether the application is running.

Take a look at the logs:

```shell
docker logs my_flask_container
```

Finally, delete the container and the image.

## Task 2

In this task you create a Dockerfile yourself.

Use the `nginx` image as the base and extend it as follows:

- It should contain an HTML file that says "Hello World".
- The HTML file should be present at `/usr/share/nginx/html/index.html` in the image.
- Build the image and start a container from it. The running container should be reachable on port 9000 and display
  the HTML page above.
- Check that everything works by opening <http://localhost:9000>.

> - The Dockerfile directives `FROM` and `COPY` are all you need for this task
> - To name the image right at build time, use the `-t` flag. Example:
>   `docker build . -t my-nginx`.
> - Inside the container, NGINX listens on port 80 by default; on the host it should be reachable on port 9000.
>   That is what the `-p` flag is for. Example: `docker run -p 9000:80 my-nginx`
