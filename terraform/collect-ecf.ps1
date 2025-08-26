$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$out = "rapport-ecf-$ts.txt"

"=== TERRAFORM OUTPUT ===" | Tee-Object -FilePath $out
terraform output | Tee-Object -FilePath $out -Append

"`n=== KUBECONFIG ===" | Tee-Object -FilePath $out -Append
aws eks update-kubeconfig --region us-east-1 --name infoline-eks-cluster | Tee-Object -FilePath $out -Append

"`n=== NODES ===" | Tee-Object -FilePath $out -Append
kubectl get nodes -o wide | Tee-Object -FilePath $out -Append

"`n=== PODS (ALL NS) ===" | Tee-Object -FilePath $out -Append
kubectl get pods -A -o wide | Tee-Object -FilePath $out -Append

"`n=== SERVICES (ALL NS) ===" | Tee-Object -FilePath $out -Append
kubectl get svc -A | Tee-Object -FilePath $out -Append

"`n=== INGRESS (ALL NS) ===" | Tee-Object -FilePath $out -Append
kubectl get ingress -A | Tee-Object -FilePath $out -Append

"`n=== MONITORING OBJECTS ===" | Tee-Object -FilePath $out -Append
kubectl -n monitoring get all | Tee-Object -FilePath $out -Append

"`n=== LOGS: ELASTICSEARCH ===" | Tee-Object -FilePath $out -Append
kubectl -n monitoring logs statefulset/elasticsearch --tail=200 | Tee-Object -FilePath $out -Append

"`n=== LOGS: KIBANA ===" | Tee-Object -FilePath $out -Append
kubectl -n monitoring logs deploy/kibana --tail=200 | Tee-Object -FilePath $out -Append

"`n=== LOGS: FLUENT-BIT ===" | Tee-Object -FilePath $out -Append
kubectl -n monitoring logs ds/fluent-bit --tail=200 | Tee-Object -FilePath $out -Append

"`n=== API GATEWAY TEST ===" | Tee-Object -FilePath $out -Append
$api = terraform output -raw api_gateway_url
"API URL: $api" | Tee-Object -FilePath $out -Append
$bodyOK = '{"username":"admin","password":"admin123"}'
$bodyKO = '{"username":"wrong","password":"bad"}'
Invoke-WebRequest -UseBasicParsing -Method POST -Uri "$api/login" -ContentType 'application/json' -Body $bodyOK -ErrorAction SilentlyContinue | Out-String | Tee-Object -FilePath $out -Append
Invoke-WebRequest -UseBasicParsing -Method POST -Uri "$api/login" -ContentType 'application/json' -Body $bodyKO -ErrorAction SilentlyContinue | Out-String | Tee-Object -FilePath $out -Append

"`n=== FRONTEND PUBLIC LB HOSTNAME ===" | Tee-Object -FilePath $out -Append
kubectl get svc frontend-public-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo | Tee-Object -FilePath $out -Append

Write-Host "Rapport généré: $out"