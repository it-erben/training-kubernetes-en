# Lab 05: Docker Networking

In this task you create your own bridge network and test it.

- Create a Docker network named `my-bridge-network` and start two containers connected to the network. Use the
  `busybox` image for this task.

> Hints:
>
> - Use the `--network <NETWORK_NAME>` argument when starting the container to connect it to a network
> - To start two containers in interactive mode with `-it`, you can open two tabs in PowerShell.

- Check whether the two containers can reach each other via `ping`.

> Hint: You can reach a container via `ping` using its name. You can find the name with `docker ps`

- Delete both containers and the network.
