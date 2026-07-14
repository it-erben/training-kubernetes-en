# Lab 05: Docker Networking

In this task you create your own bridge network and test it.

- Create a Docker network named `my-bridge-network` and start two containers connected to it. Use the
  `busybox` image for both.

> Hints:
>
> - Use the `--network <NETWORK_NAME>` argument when starting the container to connect it to a network
> - To run two containers interactively with `-it`, open two PowerShell tabs.

- Check whether the two containers can reach each other via `ping`.

> Hint: `ping` works with container names. `docker ps` shows them.

- Delete both containers and the network.
