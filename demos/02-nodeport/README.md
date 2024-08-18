# NodePort-Service auf EKS

- Erzeuge einen EKS-Cluster mit Workern in einem öffentlichen Subnetz mit Public IP
- Öffne für die Worker-Nodes alle Ports für alle Quellen
- Wende folgendes [Manifest](./manifest.yaml) an
- Rufe im Browser einen der Worker auf Port 30007 auf.
