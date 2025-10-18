# Container Images CI/CD Pipeline

Diese Repository enthält Container-Images mit einer automatisierten GitHub Actions Pipeline für Build und Deployment.

## 📁 Struktur

```
.
├── .github/workflows/
│   └── build-images.yml          # GitHub Actions Workflow
├── etcd-client/
│   ├── Containerfile             # Container Definition
│   └── image.yml                 # Image Konfiguration
└── README.md
```

## 🔧 Image Konfiguration

Jedes Image-Verzeichnis benötigt zwei Dateien:

### `Containerfile`
Standard Container-Definition (Dockerfile-kompatibel)

### `image.yml`
Konfiguration für Build-Pipeline:

```yaml
name: image-name                    # Image Name
version: 1.0.0                     # Semantic Version
description: "Image description"    # Beschreibung
registry: ghcr.io/guided-traffic  # Container Registry
platforms:                        # Unterstützte Plattformen
  - linux/amd64
  - linux/arm64
tags:                             # Zusätzliche Tags
  - latest
  - stable
```

## 🚀 Pipeline Features

### Automatische Erkennung
- Findet automatisch alle Verzeichnisse mit `Containerfile` und `image.yml`
- Baut nur geänderte Images (intelligente Erkennung)
- Support für Multi-Platform Builds (amd64, arm64)

### Trigger
- **Push auf main/develop**: Baut geänderte Images
- **Pull Request**: Build-Test ohne Push
- **Manual Dispatch**:
  - Force Rebuild aller Images
  - Spezifisches Image bauen

### Tagging-Strategie
- `{version}` - Aus image.yml Version
- `latest` - Nur für main branch
- `stable` - Nur für main branch
- `{branch}` - Für feature branches
- `pr-{number}` - Für Pull Requests
- `{branch}-{git-sha}` - Git SHA

### Security
- Trivy Vulnerability Scanning
- SARIF Upload zu GitHub Security Tab
- Registry Authentication über GITHUB_TOKEN

## 📋 Verwendung

### Neues Image hinzufügen

1. Erstelle neues Verzeichnis: `mkdir my-new-image`
2. Erstelle `Containerfile`:
```dockerfile
FROM ubuntu:24.04
# ... your container definition
```

3. Erstelle `image.yml`:
```yaml
name: my-new-image
version: 1.0.0
description: "Mein neues Container Image"
registry: ghcr.io/guided-traffic
platforms:
  - linux/amd64
  - linux/arm64
```

4. Commit und Push → Pipeline startet automatisch

### Version aktualisieren

1. Editiere `image.yml` im entsprechenden Verzeichnis
2. Erhöhe die `version`
3. Commit und Push → Neues Tagged Image wird gebaut

### Manual Build

```bash
# Via GitHub UI: Actions → Build Container Images → Run workflow
# Optionen:
# - Force rebuild all images: true/false
# - Build specific image: verzeichnis-name
```

## 🔧 Self-Hosted Runner Setup

Die Pipeline verwendet `runs-on: self-hosted`. Stelle sicher, dass:

1. **Docker/Podman** installiert ist
2. **GitHub Actions Runner** konfiguriert ist
3. **Buildx** für Multi-Platform Support verfügbar ist
4. **Zugriff auf Container Registry** (GHCR) gewährleistet ist

### Runner Requirements
```bash
# Docker & Buildx
docker buildx version

# Optional: yq für besseres YAML parsing
sudo apt install yq  # oder via snap/brew
```

## 📊 Monitoring

- **GitHub Actions**: Build Status und Logs
- **GitHub Security**: Vulnerability Scan Reports
- **GitHub Packages**: Published Container Images

## 🏷️ Beispiel Tags

Für `etcd-client:1.0.0` auf main branch:
```
ghcr.io/guided-traffic/etcd-client:1.0.0
ghcr.io/guided-traffic/etcd-client:latest
ghcr.io/guided-traffic/etcd-client:stable
ghcr.io/guided-traffic/etcd-client:main-abc1234
```

## 🔄 Entwicklung

### Lokaler Test
```bash
# Image lokal bauen
cd etcd-client
docker build -t etcd-client:test -f Containerfile .

# Multi-Platform Build testen
docker buildx build --platform linux/amd64,linux/arm64 \
  -t etcd-client:test -f Containerfile .
```

### Pipeline Debug
```bash
# Workflow Syntax prüfen
gh workflow view build-images.yml

# Lokale Simulation mit act (optional)
act -j build-images
```