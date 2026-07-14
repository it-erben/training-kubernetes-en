# Solution: Services

## Pods and Service (Deployment and ClusterIP Service)

To start the application and the service, apply the following YAML files:

- Deployment for the application: `kubectl apply -f deployment.yaml`
- Service of type ClusterIP: `kubectl apply -f service-clusterip.yaml`

The YAML definitions are as follows:

**`deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  labels:
    app: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: nginx:1.29
        ports:
        - containerPort: 80
```

**`service-clusterip.yaml`**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-clusterip
spec:
  selector:
    app: myapp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

## Testing Access

- Determine the ClusterIP: `kubectl get svc myapp-clusterip -o wide`
- Start busybox: `kubectl run -it curl --rm --restart=Never --image=busybox:1.37 -- wget -qO- http://<CLUSTER_IP>`
- Alternatively via DNS: `wget -qO- http://myapp-clusterip`

## Changing the Service Type (NodePort Service)

To change the service type to NodePort, apply the following YAML file. Note that this creates a new service.

- Service of type NodePort: `kubectl apply -f service-nodeport.yaml`

The YAML definition is as follows:

**`service-nodeport.yaml`**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-nodeport
spec:
  selector:
    app: myapp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: NodePort
```

- Show the NodePort: `kubectl get svc myapp-nodeport -o jsonpath='{.spec.ports[0].nodePort}'`
- Test with Minikube: `minikube service myapp-nodeport`
