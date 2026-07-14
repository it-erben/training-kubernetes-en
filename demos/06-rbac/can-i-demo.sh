#!/usr/bin/env bash
#
# kubectl auth can-i — runnable demo
#
# Setup:   kubectl apply -f rbac.yaml   (ServiceAccounts admin + developer)
# Run:     ./can-i-demo.sh
# Cleanup: kubectl delete -f rbac.yaml ; kubectl delete ns can-i-demo
#
# Each block prints the command, then runs it. Exit code: 0 = yes, 1 = no.
set -u

run() {
  echo
  echo "\$ $*"
  "$@"
}

echo "######################################################################"
echo "# 0. Setup — create the two ServiceAccounts + Roles/Bindings"
echo "######################################################################"
run kubectl apply -f rbac.yaml

echo
echo "######################################################################"
echo "# 1. Who am I? — check your OWN permissions (no --as)"
echo "######################################################################"
# Cluster-admin kubeconfig -> almost everything is 'yes'
run kubectl auth can-i create deployments
run kubectl auth can-i get pods
run kubectl auth can-i '*' '*'                 # full god-mode check

echo
echo "######################################################################"
echo "# 2. Impersonation — check ANOTHER identity with --as"
echo "######################################################################"
# admin SA: full verbs on pods/replicasets/cronjobs (Role 'admin')
run kubectl auth can-i delete pods        --as=system:serviceaccount:default:admin
run kubectl auth can-i create cronjobs    --as=system:serviceaccount:default:admin

# developer SA: only get/list/watch (Role 'developer')
run kubectl auth can-i get    pods        --as=system:serviceaccount:default:developer
run kubectl auth can-i create pods        --as=system:serviceaccount:default:developer   # -> no
run kubectl auth can-i delete pods        --as=system:serviceaccount:default:developer   # -> no

echo
echo "######################################################################"
echo "# 3. --as-group — impersonate a USER in a GROUP"
echo "######################################################################"
run kubectl auth can-i get pods --as=alice --as-group=system:authenticated

echo
echo "######################################################################"
echo "# 4. Scope to a specific NAMESPACE (-n) vs all namespaces (--all-namespaces)"
echo "######################################################################"
run kubectl auth can-i list pods -n kube-system --as=system:serviceaccount:default:developer
run kubectl auth can-i list pods --all-namespaces --as=system:serviceaccount:default:developer

echo
echo "######################################################################"
echo "# 5. Subresources and named resources (use '/' and a slash for the name)"
echo "######################################################################"
run kubectl auth can-i create pods/exec   --as=system:serviceaccount:default:admin
run kubectl auth can-i get    pods/log     --as=system:serviceaccount:default:developer
# verb on a specific named object:
run kubectl auth can-i get pods/my-pod     --as=system:serviceaccount:default:developer

echo
echo "######################################################################"
echo "# 6. Non-resource URLs (the API paths, not k8s objects)"
echo "######################################################################"
run kubectl auth can-i get /healthz        --as=system:serviceaccount:default:developer
run kubectl auth can-i get /metrics        --as=system:serviceaccount:default:developer

echo
echo "######################################################################"
echo "# 7. --list — dump the FULL permission matrix for an identity"
echo "######################################################################"
run kubectl auth can-i --list --as=system:serviceaccount:default:developer

echo
echo "######################################################################"
echo "# 8. Quiet mode for scripts — no output, just exit code"
echo "######################################################################"
echo
echo '$ if kubectl auth can-i create pods --as=...:developer -q; then echo CAN; else echo CANNOT; fi'
if kubectl auth can-i create pods --as=system:serviceaccount:default:developer -q; then
  echo "CAN create pods"
else
  echo "CANNOT create pods (exit code 1)"
fi

echo
echo "######################################################################"
echo "# Done. Cleanup with:"
echo "#   kubectl delete -f rbac.yaml"
echo "######################################################################"
