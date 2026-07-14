# Azure Policies for secure AKS clusters

---

## Critical

| # | Policy | Rationale |
| --- | --- | --- |
| 1 | **Kubernetes cluster containers should only use allowed images** | Blocks unauthorized images |
| 2 | **Kubernetes clusters should not allow privileged containers** | Root access to the host, high risk |
| 3 | **Kubernetes cluster pods should only use approved host network and port range** | Prevents network sniffing |
| 4 | **Kubernetes clusters should disable automounting API credentials** | No auto-mounting of SA tokens in pods |
| 5 | **Kubernetes cluster containers should not share host process ID or host IPC namespace** | Container isolation |

---

## High

| # | Policy | Rationale |
| --- | --- | --- |
| 6 | **Kubernetes cluster containers should run with a read only root file system** | Prevents malware persistence |
| 7 | **Kubernetes cluster pods should use specified labels** | Consistent labels for governance and monitoring |
| 8 | **Kubernetes cluster containers should only use allowed capabilities** | Only the Linux capabilities you need |
| 9 | **Kubernetes clusters should not use the default namespace** | Better isolation and RBAC through namespaces |
| 10 | **Kubernetes cluster containers CPU and memory resource limits should not exceed specified limits** | Anti-DoS |

---

## Medium

| # | Policy | Rationale |
| --- | --- | --- |
| 11 | **Kubernetes cluster services should only use allowed external IPs** | Controls exposed external IPs |
| 12 | **Kubernetes cluster pods should only use allowed volume types** | For example, no hostPath volumes |
| 13 | **Kubernetes clusters should use internal load balancers** | Keeps services off the public internet |
| 14 | **Kubernetes cluster containers should only use allowed AppArmor profiles** | AppArmor profiles for isolation |
| 15 | **Kubernetes cluster containers should only use allowed seccomp profiles** | Restricts the allowed syscalls |

---

## Recommended

| # | Policy | Rationale |
| --- | --- | --- |
| 16 | **Kubernetes clusters should be accessible only over HTTPS** | Enforces encrypted API server communication |
| 17 | **Kubernetes cluster should not allow container privilege escalation** | No `allowPrivilegeEscalation` |
| 18 | **Kubernetes clusters should have Defender profile enabled** | Microsoft Defender for runtime protection |
| 19 | **Authorized IP ranges should be defined on Kubernetes Services** | API server access limited to known IPs |
| 20 | **Role-Based Access Control should be used on Kubernetes Services** | Enforces RBAC instead of legacy ABAC |

---

## Additional governance policies

| # | Policy | Rationale |
| --- | --- | --- |
| 21 | **Azure Kubernetes Service Clusters should have local authentication methods disabled** | Only Azure AD allowed |
| 22 | **Azure Kubernetes Service Clusters should enable Container Storage Interface (CSI)** | Modern storage drivers |
| 23 | **Kubernetes clusters should gate deployment of vulnerable images** | Blocks images with known CVEs |

---

### Further reading

- [Azure Policy for Kubernetes – documentation](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes)
- [AKS Security Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
- [Pod Security Standards (PSS)](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
