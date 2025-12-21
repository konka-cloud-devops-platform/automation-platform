#!/bin/bash
# kubectl port-forward svc/gateway-nginx -n ngf-gatewayapi --address 0.0.0.0 8080:80 & 
commands=(
  "kubectl port-forward svc/argocd-server -n argocd --address 0.0.0.0 8080:80"
  "kubectl port-forward svc/prometheus-grafana -n monitoring --address 0.0.0.0 8081:80"
  "kubectl port-forward svc/nginx-kibana -n logging --address 0.0.0.0 8082:80"
  "kubectl port-forward svc/dev-frontend -n instana --address 0.0.0.0 8083:80"
  "kubectl port-forward svc/kiali -n istio-system --address 0.0.0.0 8084:20001"
  "kubectl port-forward -n istio-system svc/jaeger-query --address 0.0.0.0 8085:80"
  "kubectl port-forward -n crud svc/crud-frontend  --address 0.0.0.0 8086:80"
)

run_cmd() {
  local cmd="$1"
  echo "Do you want to run: $cmd ? (y/n)"
  read -r answer
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    eval "$cmd &"
    echo "✅ Started: $cmd"
  else
    echo "❌ Skipped: $cmd"
  fi
}

echo "Do you want to run ALL commands at once? (y/n)"
read -r all_choice

if [[ "$all_choice" == "y" || "$all_choice" == "Y" ]]; then
  echo "🚀 Running all port-forward commands..."
  for cmd in "${commands[@]}"; do
    eval "$cmd &"
    echo "✅ Started: $cmd"
  done
else
  echo "👉 Running one by one with confirmation..."
  for cmd in "${commands[@]}"; do
    run_cmd "$cmd"
  done
fi
# sudo lsof -t -i:8080 -i:8081 -i:8082 -i:8083 -i:8084 | xargs -r sudo kill -9
# sudo netstat -tulnp | grep -E '8080|8081|8082|8083|8084'
