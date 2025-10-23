# Dockerfile Exercises

## Task 1: Building and Running a Flask Application

In this task, you will take a small Flask application, package it into a Docker image, and run a container from it.

1.  First, **build the image** using the files provided in this directory.

    ```shell
    docker build -t my_flask_app .
    ```

2.  Next, **start a container** from the image. It should run in the background (`-d`), be named `my_flask_container`, and map the container's port 80 to the host's port 8080.

    ```shell
    docker run -d -p 8080:80 --name my_flask_container my_flask_app
    ```

3.  Open a browser to **`http://localhost:8080`** and verify that the application is running.

4.  **Inspect the logs** of the running container.

    ```shell
    docker logs my_flask_container
    ```

5.  Finally, **delete the container and the image**.

-----

## Task 2: Creating a Custom NGINX Image

In this task, you will **create your own Dockerfile**.

Base your image on the official **`nginx`** image and extend it as follows:

1.  **Create a local HTML file** (e.g., `index.html`) containing the text **"Hello World"**.

2.  Your Dockerfile must ensure that this HTML file is present in the image at the path **`/usr/share/nginx/html/index.html`**.

3.  **Build the image** and give it a name (e.g., `my-nginx`).

4.  **Start a container** from your new image. The running web server must be accessible on **host port 9000** and display the HTML page you provided.

5.  **Verify that everything works** by navigating to **`http://localhost:9000`**.

>   * **Hints:**
      >       * For this task, the Dockerfile directives **`FROM`** and **`COPY`** are sufficient.
>       * Use the **`-t`** flag to name an image directly during the build process. Example: `docker build . -t my-nginx`.
>       * NGINX listens on port 80 inside the container by default. To make it reachable on host port 9000, use the **`-p`** argument. Example: `docker run -p 9000:80 my-nginx`.
