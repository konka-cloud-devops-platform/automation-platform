#!/bin/bash

echo "==================External Secrets Operator Installation===================="
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  --set installCRDs=true

echo "===============ArgoCD and Prometheus Installation=========================="
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl create namespace monitoring
helm install prometheus oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack --namespace monitoring

echo "===============Istio Helm Charts Installation=============================="
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add kiali https://kiali.org/helm-charts
helm repo update
kubectl create namespace istio-system

helm upgrade --install istio-base istio/base -n istio-system
helm upgrade --install istiod istio/istiod -n istio-system --wait
# helm upgrade --install istio-ingressgateway istio/gateway -n istio-system
# helm upgrade --install istio-egressgateway istio/gateway -n istio-system


helm upgrade --install kiali-server kiali/kiali-server \
  -n istio-system \
  --set auth.strategy="anonymous" \
  --set external_services.prometheus.url="http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090" \
  --set external_services.grafana.enabled=true \
  --set external_services.grafana.in_cluster_url="http://prometheus-grafana.monitoring.svc.cluster.local:80" \
  --set external_services.grafana.external_url="http://prometheus-grafana.monitoring.svc.cluster.local:80"


helm upgrade --install jaeger jaegertracing/jaeger \
  --namespace istio-system \
  --set provisionDataStore.cassandra=false \
  --set storage.type=memory \
  --set persistence.enabled=false \
  --set collector.zipkinHostPort=:9411

echo "====================NGINX Fabric Controller Installation==================="
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.1.0" | kubectl apply -f -
helm upgrade --install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --create-namespace -n ngf-gatewayapi