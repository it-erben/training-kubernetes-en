#!/usr/bin/env bash
kubectl auth can-i '*' 'pods' --as=system:serviceaccount:default:admin
kubectl auth can-i '*' 'replicasets' --as=system:serviceaccount:default:admin
kubectl auth can-i '*' 'cronjobs' --as=system:serviceaccount:default:admin

kubectl auth can-i 'get' 'pods' --as=system:serviceaccount:default:developer
kubectl auth can-i 'create' 'pods' --as=system:serviceaccount:default:developer
