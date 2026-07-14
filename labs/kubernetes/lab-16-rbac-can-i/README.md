# Lab 16: Creating and Debugging ServiceAccounts, Roles, and RoleBindings in Kubernetes

In this exercise you will create two ServiceAccounts and corresponding roles in Kubernetes. These roles are
supposed to have different access rights to certain resources. Afterwards, you will bind the ServiceAccounts to the
roles and verify that the permissions have been applied correctly.

## The `kubectl auth can-i` Command

kubectl has a built-in feature that checks whether a principal in Kubernetes has certain permissions.
Here is the documentation: [](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i/)
For example, this is what the command looks like that checks whether the ServiceAccount "admin" in the default namespace
is allowed to list all pods:

```bash
kubectl auth can-i list pods --as=system:serviceaccount:default:admin -n default
```

## Create ServiceAccounts

- Create a ServiceAccount named `admin` in the default namespace.
- Create another ServiceAccount named `developer` in the default namespace.

## Create Roles

- Create a role named `admin` in the default namespace. This role should have full access (\* on all verbs) to the
  resource types `Pod`, `ReplicaSet`, and `CronJob`.
- Create a role named `developer` in the default namespace. This role should have read-only access (`get`, `list`, `watch`)
  to the resource types `Pod`, `ReplicaSet`, and `CronJob`.

## Create RoleBindings

- Bind the `admin` ServiceAccount to the `admin` role with a RoleBinding.
- Bind the `developer` ServiceAccount to the `developer` role.

## Verify the Permissions

- Use the `kubectl auth can-i` command to verify that the admin ServiceAccount has full access to the resources
  mentioned above.
- Also verify that the developer ServiceAccount only has read access and cannot perform any other actions.
