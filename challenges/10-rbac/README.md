## Assignment 1: User, Context, and `kubectl` Execution

The premise of this exercise is to **create a new user** and **add her to the kubeconfig file**. You will then **define a context** that uses the user, **switch to the context**, and **execute a `kubectl` command**.

> You will need to set up certificates in this assignment. The [Kubernetes documentation](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#normal-user) has information on this.

* Create a **certificate for a user named mary**. Do **not** provide any permissions to the user.
* **Add the user to the kubeconfig file.** Define the context named **`mary-context`** that assigns the user to a cluster already available in the kubeconfig file.
* **Set the currently selected context to `mary-context`.**
* **Create a Pod using `kubectl`.**

**What result do you expect to see?**

***

## Assignment 2: RBAC and Service Accounts

You will use **RBAC** to grant permissions to a **service account**. The permissions should apply only to **certain API resources and operations**.

* Create a new namespace named **`t23`**.
* Create a Pod named **`service-list`** in the namespace `t23`. The container uses the image **`alpine/curl:3.14`** and makes a `curl` call to the Kubernetes API that **lists Service objects in the default namespace in an infinite loop**.
* Create and **attach the service account `api-call` to the Pod.**
* Inspect the container logs after the Pod has been started. **What response do you expect to see from the `curl` command?**
* Assign a **ClusterRole** and **RoleBinding** to the service account that allows **only the operation needed by the Pod**. Note the response from the `curl` command.

***

## Assignment 3: Identifying Admission Controller Plugins

* **Identify the admission controller plugins** that have been configured for the API server.
* **Locate the configuration file of the API server.**
* **Inspect the command-line flag that defines the admission controller plugins.**
* **Capture the value.**
