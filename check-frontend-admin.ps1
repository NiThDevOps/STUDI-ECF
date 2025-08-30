# =====================================================================================
# Check Frontend Admin on EKS - generates a timestamped report
# =====================================================================================

$ErrorActionPreference = "Continue"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$out = "report-frontend-admin-$ts.txt"

function Log($text) {
  $text | Tee-Object -FilePath $out -Append
}

"=== FRONTEND-ADMIN CHECK ($(Get-Date)) ===" | Tee-Object -FilePath $out

# 1) Pod name
$pod = kubectl get pods -l app=frontend-admin -o jsonpath='{.items[0].metadata.name}'
Log "`n[1] Pod:"
Log "pod = $pod"

if (-not $pod) {
  Log "Aucun pod trouvé avec le label app=frontend-admin. Abandon."
  exit 1
}

# 2) Container image (declared on Deployment) + imageID (running digest)
Log "`n[2] Image déclarée dans le Deployment:"
kubectl get deploy frontend-admin -o jsonpath='{.spec.template.spec.containers[0].image}' | Tee-Object -FilePath $out -Append

Log "`n[2bis] Image ID réellement utilisée par le pod (digest):"
kubectl get pod $pod -o jsonpath='{.status.containerStatuses[0].imageID}' | Tee-Object -FilePath $out -Append

# 3) Service LB hostname
Log "`n[3] Service LoadBalancer hostname:"
kubectl get svc frontend-admin-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' | Tee-Object -FilePath $out -Append

# 4) Liste des fichiers servis par Nginx
Log "`n[4] Contenu /usr/share/nginx/html (premières lignes):"
kubectl exec -it $pod -- sh -c "ls -lah /usr/share/nginx/html | sed -n '1,80p'" | Tee-Object -FilePath $out -Append

# 5) Début du index.html (si présent)
Log "`n[5] Début de index.html:"
kubectl exec -it $pod -- sh -c "head -n 30 /usr/share/nginx/html/index.html || true" | Tee-Object -FilePath $out -Append

# 6) Nginx access/error logs (si existants dans l'image)
Log "`n[6] Logs Nginx (si présents):"
kubectl exec -it $pod -- sh -c "ls -lah /var/log/nginx || true" | Tee-Object -FilePath $out -Append
kubectl exec -it $pod -- sh -c "test -f /var/log/nginx/error.log && tail -n 100 /var/log/nginx/error.log || echo 'Pas de /var/log/nginx/error.log'" | Tee-Object -FilePath $out -Append
kubectl exec -it $pod -- sh -c "test -f /var/log/nginx/access.log && tail -n 50 /var/log/nginx/access.log || echo 'Pas de /var/log/nginx/access.log'" | Tee-Object -FilePath $out -Append

# 7) Test HTTP externe (via LB) en HEAD et GET
$ADM = kubectl get svc frontend-admin-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
if ($ADM) {
  Log "`n[7] Test HTTP externe (HEAD + GET) via LB: http://$ADM/"
  try {
    (Invoke-WebRequest -UseBasicParsing -Method Head -Uri ("http://{0}/" -f $ADM) -TimeoutSec 15) | Select-Object StatusCode, StatusDescription, Headers | Out-String | Tee-Object -FilePath $out -Append
  } catch { $_ | Out-String | Tee-Object -FilePath $out -Append }

  try {
    (Invoke-WebRequest -UseBasicParsing -Uri ("http://{0}/" -f $ADM) -TimeoutSec 15) | Select-Object StatusCode, StatusDescription | Out-String | Tee-Object -FilePath $out -Append
  } catch { $_ | Out-String | Tee-Object -FilePath $out -Append }
} else {
  Log "Pas d'hostname LB récupéré pour frontend-admin-service."
}

# 8) Variables d'env du conteneur (utile pour debug build)
Log "`n[8] Variables d'environnement (si lisibles):"
kubectl exec -it $pod -- sh -c "env | sort" | Tee-Object -FilePath $out -Append

Log "`n=== FIN - Rapport écrit dans: $out ==="
Write-Host "`nRapport généré: $out"