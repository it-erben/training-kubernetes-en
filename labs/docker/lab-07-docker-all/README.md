# Lab 07: Final exercise – putting it all together

Goal: Containerize an existing Node.js program, inject content via a bind mount, make it reachable in its own
network and clean up properly at the end.

---

## Step 1 – Create a Dockerfile

- The file `app.js` provides an HTTP web server. Make sure the server listens on **0.0.0.0** and **port 3000**.

**`app.js`:**

```javascript
const http = require("http");
const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Hello from Docker + Node.js!\n");
});

server.listen(PORT, () => {
  console.log(`Server running at http://0.0.0.0:${PORT}/`);
});
```

- Create a Dockerfile with:
  - a pinned base image (e.g. `node:20-alpine`)
  - a sensible `WORKDIR`
  - the required files copied in
  - startup via `CMD`
  - optionally `EXPOSE 3000`
- Build an image with a unique name (e.g. prefixed with the exercise name).

**Success criterion:** The image builds, and you can start a container from it.

---

## Step 2 – Start a container

- Start a container from your image and make the service reachable locally.
- Check that it responds in a browser or via an HTTP client.

**Success criterion:** HTTP response (status 200) with the expected answer from the app.

---

## Step 3 – Test a bind mount

`app.js` should return the content of the file `/tmp/content/file.txt` if it exists.

- Start a (new) container **with** a bind mount on `/tmp/content` (host directory of your choice).
- Create a `file.txt` in the **host directory** and change its content.
- Call the endpoint again and observe the change.

**Note:** Make sure no leftover container is still blocking the port mapping.

**Success criterion:** The response always reflects the current content of the host `file.txt`.

---

## Step 4 – Set up a network

- Create your own user-defined Docker network.
- Start the web server container **in** the new network (internal port 3000).
- Start a second, lightweight container (e.g. `alpine`/`busybox`) **in the same network**.
- From the second container, call the web server **by container name** and **port 3000**.

**Note:** No port mapping to the host is needed for container-to-container access.

**Success criterion:** An HTTP request from the second container to `http://<webserver-name>:3000` returns the
expected response.

---

## Step 5 – Clean up

- Stop all containers from this exercise.
- Remove **only** the containers, images, bind mount contents and the network created in this exercise.
  - Use consistent names or a shared label on all resources to make this easier.

**Success criterion:** `docker ps`, `docker images` and the network/volume overviews show no resources with the
exercise prefix/label.

---
