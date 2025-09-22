# Docker Networking

In dieser Aufgabe legst du ein eigenes Bridge-Netzwerk an und testest es.

- Lege ein Docker Network mit dem Namen `my-bridge` an und starte zwei Container mit Verbindung zum Network. Benutze das Image `busybox` für diese Aufgabe.

> Verwende das `--network <NETWORK_NAME>`-Argument beim Start des Containers, um es mit einem Netzwerk zu verbinden

- Prüfe, ob die beiden Container sich per `ping` erreichen können. 

> Hinweis: Du erreichst einen Container über `ping` mit seinem Namen. Den Namen findest du mit `docker ps`

- Lösche beide Container und das Netzwerk.
