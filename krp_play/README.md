# krp_play

Flutter app for the **UTM KRP Sport Court Booking Application** (student and admin UI, mobile and web).

See the [project README](../README.md) for the overview, setup and team workflow.

| Folder | Contents |
|---|---|
| `lib/` | Flutter source: models, screens (`screens/admin/` for admin), services, widgets |
| `test/` | Widget tests (`flutter test`) |
| `backend/` | Node.js + Express payment backend: see [backend/README.md](backend/README.md) |
| `frontend/` | Early React (Vite) UI prototype |
| `run_web.ps1` | Runs the app in Chrome against the payment backend |

## Quick start

```powershell
flutter pub get
.\run_web.ps1                                  # backend at http://localhost:3000
.\run_web.ps1 https://<your-ngrok-domain>      # backend through ngrok
```
