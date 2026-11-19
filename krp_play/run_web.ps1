# Runs the app in Chrome with the local Flutter web engine (avoids the blank page
# when gstatic.com is blocked) and points checkout at the local payment backend.
# Usage: .\run_web.ps1            (backend at http://localhost:3000)
#        .\run_web.ps1 https://xxxx-3000.asse.devtunnels.ms
param([string]$BackendUrl = "http://localhost:3000")

Set-Location $PSScriptRoot
flutter run -d chrome --no-web-resources-cdn "--dart-define=PAYMENT_BACKEND_URL=$BackendUrl"
