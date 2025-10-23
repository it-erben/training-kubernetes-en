# Docker Networking

In this task, you will create and test your own **Bridge Network** in Docker.

1.  **Create a Docker Network** named **`my-bridge`**.
2.  **Start two separate containers** using the **`busybox`** image, connecting both to the newly created network. Give them distinct, memorable names (e.g., `container-a` and `container-b`).

> **Hints:**
> * Use the **`--network <NETWORK_NAME>`** argument when starting the containers to connect them to the network.
> * To start two interactive containers using **`-it`**, you can open two separate terminal sessions (or tabs).

3.  From one container, **verify that the two containers can reach each other** using the **`ping`** command.

> **Hint:** You can reach a container via `ping` using its **name**. Use `docker ps` to find the container name.

4.  Finally, **delete both containers and the network**.
