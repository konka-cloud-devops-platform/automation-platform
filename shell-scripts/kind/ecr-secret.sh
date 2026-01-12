#!/bin/bash
# 1. Delete old secret if it exists
kubectl delete secret ecr-secret -n instana --ignore-not-found

# 2. Create fresh ECR secret
kubectl create secret docker-registry ecr-secret \
  --docker-server=384570460482.dkr.ecr.ap-south-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-south-1) \
  --namespace=instana

# 3. Verify secret was created
kubectl get secret ecr-secret -n instana

# 4. Patch ALL your StatefulSets to use the secret
kubectl patch statefulset dev-mongo -n instana -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'

kubectl patch statefulset dev-mysql -n instana -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'

kubectl patch statefulset dev-rabbitmq -n instana -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'

kubectl patch statefulset dev-redis -n instana -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'

kubectl patch deployment dev-catalogue -n instana -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'

kubectl patch deployment dev-cart -n instana -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'

kubectl patch deployment dev-user -n instana -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'

kubectl patch deployment dev-shipping -n instana -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'

kubectl patch deployment dev-payment -n instana -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'

kubectl patch deployment dev-frontend -n instana -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'

# 5. Watch pods restart with new credentials
kubectl get pods -n instana -w