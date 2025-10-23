# Final Exercise: Bringing It All Together

**Goal:** Containerize an existing Node.js application, inject content via a Bind Mount, make it accessible within its own custom network, and clean up thoroughly at the end.

***

## Step 1 – Create the Dockerfile

* The provided file **`app.js`** runs an HTTP web server. Ensure the server is configured to listen on **`0.0.0.0`** and **Port `3000`**.
* **Create a Dockerfile** with the following:
    * A stable **base image** (e.g., `node:20-alpine`).
    * A meaningful **`WORKDIR`**.
    * Instructions to **copy** the necessary files (including `app.js`).
    * A **`CMD`** instruction to start the application.
    * (Optional) **`EXPOSE 3000`**.
* **Build an image** with a unique name (e.g., using the exercise name as a prefix).

**Success Criterion:** Image is built; a container can be started from it.

***

## Step 2 – Start the Container

* **Start a container** from your image, making the service locally accessible on your host machine.
* **Verify accessibility** using a browser or an HTTP client (e.g., `curl`).

**Success Criterion:** You receive an **HTTP Response (Status 200)** with the expected application message.

***

## Step 3 – Test the Bind Mount

The **`app.js`** application is designed to return the content of the file **`/tmp/content/file.txt`** if it exists.

* **Start a (new) container** with a **Bind Mount** configured to map a **Host Directory** (chosen by you) to the container path **`/tmp/content`**.
* **Create a `file.txt`** in the **Host Directory** and change its content.
* Call the HTTP endpoint again and **observe the change** in the response.

**Note:** Ensure no currently running container is blocking the required port mapping.

**Success Criterion:** The HTTP response contains the **current content** of the host's `file.txt`.

***

## Step 4 – Establish Networking

* **Create your own custom Docker network**.
* **Start the web server container** (internal port 3000) **within** the new network, giving it a descriptive name.
* **Start a second, lightweight container** (e.g., `alpine` or `busybox`) **within the same network**.
* From the second container, **call the web server** using its **Container Name** and **Port 3000**.

**Note:** For container-to-container access, no port mapping to the host is required.

**Success Criterion:** An HTTP request from the second container to `http://<webserver-name>:3000` returns the expected response.

***

## Step 5 – Clean Up

* **Stop all containers** created for this exercise.
* **Remove *only* the resources** created in this exercise: containers, images, the content from the Bind Mount (host-side), and the custom network.
    * Use consistent names or a label (if you set one on all resources) to facilitate cleanup.

**Success Criterion:** `docker ps`, `docker images`, and the network/volume overviews show **no remaining resources** with the exercise's prefix/label.
