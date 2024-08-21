# Erstellen von ServiceAccounts, Rollen und RoleBindings in Kubernetes

In dieser Übung wirst du zwei ServiceAccounts sowie entsprechende Rollen in Kubernetes erstellen. Diese Rollen sollen unterschiedliche Zugriffsrechte auf bestimmte Ressourcen haben. Anschließend wirst du die ServiceAccounts mit den Rollen verbinden und überprüfen, ob die Berechtigungen korrekt angewendet wurden.

## ServiceAccounts erstellen

- Erstelle einen ServiceAccount namens `admin` im Default-Namespace.
- Erstelle einen weiteren ServiceAccount namens `developer` im Default-Namespace.

## Erstelle Rollen

- Erstelle eine Rolle namens `admin` im Default-Namespace. Diese Rolle soll Vollzugriff (* auf alle Verben) auf die Ressourcentypen `Pod`, `ReplicaSet` und `CronJob` haben.
- Erstelle eine Rolle namens `developer` im Default-Namespace. Diese Rolle soll nur Lesezugriff (`get`, `list`, `watch`) auf die Ressourcentypen `Pod`, `ReplicaSet` und `CronJob` haben.

## Erstelle RoleBindings

- Verbinde den `admin`-ServiceAccount mit der `admin`-Rolle mit einem RoleBinding.
- Verbinde den `developer`-ServiceAccount mit der `developer`-Rolle.

## Überprüfe die Berechtigungen:

- Verwende den Befehl `kubectl auth can-i`, um zu überprüfen, ob der ServiceAccount admin Vollzugriff auf die genannten Ressourcen hat.
- Überprüfe auch, ob der ServiceAccount developer nur Lesezugriff hat und keine anderen Aktionen ausführen kann.
