# Creating ServiceAccounts, Roles, and RoleBindings in Kubernetes

In this exercise, you will create **two ServiceAccounts** and their corresponding **Roles** in Kubernetes. These Roles will have distinct access permissions to specific resources. You will then connect the ServiceAccounts to the Roles and verify that the permissions have been applied correctly.

***

## Create ServiceAccounts

* Create a ServiceAccount named **`admin`** in the `default` namespace.
* Create another ServiceAccount named **`developer`** in the `default` namespace.

***

## Create Roles

* Create a Role named **`admin`** in the `default` namespace. This Role must have **full access** (the `*` wildcard for all verbs) to the resource types **`Pod`**, **`ReplicaSet`**, and **`CronJob`**.
* Create a Role named **`developer`** in the `default` namespace. This Role must have **read-only access** (`get`, `list`, `watch`) to the resource types **`Pod`**, **`ReplicaSet`**, and **`CronJob`**.

***

## Create RoleBindings

* Connect the **`admin`** ServiceAccount to the **`admin`** Role using a **RoleBinding**.
* Connect the **`developer`** ServiceAccount to the **`developer`** Role using a **RoleBinding**.

***

## Verify Permissions

* Use the **`kubectl auth can-i`** command to verify that the **`admin`** ServiceAccount has **full access** to the specified resources.
* Also, verify that the **`developer`** ServiceAccount has **read-only access** and **cannot perform any other actions** (i.e., verbs like `create` or `delete`).
