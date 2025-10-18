# Supply Chain Attestation

Dieses Repository implementiert umfassende Supply Chain Security für Container Images mit folgenden Komponenten:

## 🔒 Sicherheitsfeatures

### SLSA (Supply-chain Levels for Software Artifacts)
- **SLSA Level 3** Provenance Generation
- Automatische Attestierung des Build-Prozesses
- Unveränderliche Aufzeichnung von Build-Parametern und Umgebung
- Integration mit GitHub's nativer Attestation API

### SBOM (Software Bill of Materials)
- **SPDX** und **CycloneDX** Format Support
- Automatische Generierung mit [Syft](https://github.com/anchore/syft)
- Vollständige Abhängigkeitsinventarisierung
- Upload als Build-Artifacts für langfristige Archivierung

### Container Signing mit Cosign
- **Keyless Signing** mit OpenID Connect
- Signierung von Image und SBOM
- Integration mit [Sigstore](https://sigstore.dev/) Infrastruktur
- Transparente Verification Logs

## 📋 Generierte Attestationen

Für jedes Image werden folgende Attestationen erstellt:

### 1. SLSA Provenance
```json
{
  "buildType": "https://github.com/docker/build-push-action@v5",
  "builder": {
    "id": "https://github.com/guided-traffic/container-images/.github/workflows/build-images.yml@main"
  },
  "metadata": {
    "buildInvocationId": "...",
    "buildStartedOn": "...",
    "buildFinishedOn": "..."
  }
}
```

### 2. SBOM Attestation
- **Package Inventory**: Alle installierten Pakete mit Versionen
- **Vulnerability Data**: CVE-Informationen für bekannte Schwachstellen
- **License Information**: Lizenz-Compliance Tracking
- **File Hashes**: Integrity Verification

### 3. Cosign Signature
- **Keyless Signature**: Basierend auf OIDC Identity
- **Certificate Transparency**: Öffentlich verifizierbar
- **Timestamping**: Genaue Signierung-Zeit

## 🔍 Verification

### Image Signature prüfen
```bash
# Grundlegende Signatur-Verification
cosign verify hansfischer/etcd-client:1.0.0

# Mit spezifischem Digest
cosign verify hansfischer/etcd-client@sha256:abc123...
```

### Provenance prüfen
```bash
# SLSA Provenance anzeigen
cosign verify-attestation \
  --type slsaprovenance \
  hansfischer/etcd-client:1.0.0

# Spezifische Build-Informationen
cosign verify-attestation \
  --type slsaprovenance \
  --certificate-identity-regexp=".*guided-traffic.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  hansfischer/etcd-client:1.0.0
```

### SBOM anzeigen
```bash
# SBOM Attestation prüfen
cosign verify-attestation \
  --type spdx \
  hansfischer/etcd-client:1.0.0

# SBOM zur lokalen Analyse herunterladen
cosign download attestation \
  --predicate-type https://spdx.dev/Document \
  hansfischer/etcd-client:1.0.0 > etcd-client-sbom.json
```

## 🛡️ Security Policy

### Build Environment
- **Isolated Runners**: Self-hosted mit kontrollierten Umgebungen
- **Minimal Permissions**: Least-privilege Prinzip
- **Audit Logs**: Vollständige Nachverfolgbarkeit

### Supply Chain Protection
- **Dependency Pinning**: Exakte Versionen in Containerfile
- **Base Image Verification**: Nur signierte Ubuntu Images
- **Multi-Stage Builds**: Reduzierte Attack Surface

### Compliance Standards
- **NIST SSDF**: Software Supply Chain Framework
- **SLSA Level 3**: Build Integrity und Provenance
- **SPDX 2.3**: Standard SBOM Format
- **CycloneDX**: Vulnerability Exchange Format

## 📊 Monitoring & Alerting

### GitHub Security Features
- **Dependency Scanning**: Automatische CVE Detection
- **Secret Scanning**: Credential Leak Prevention
- **Code Scanning**: Static Analysis mit CodeQL
- **Supply Chain Security**: Attestation Monitoring

### Trivy Integration
- **Vulnerability Scanning**: OS und Application Packages
- **Misconfiguration Detection**: Container Best Practices
- **SARIF Integration**: GitHub Security Tab

## 🔄 Workflow Integration

### Automatische Triggers
```yaml
# Bei Code-Änderungen
on:
  push:
    paths: ['**/Containerfile', '**/image.yml']

# Manual mit Options
workflow_dispatch:
  inputs:
    force_rebuild: boolean
    specific_image: string
```

### Conditional Execution
- **PR Mode**: Build ohne Push/Sign für Testing
- **Main Branch**: Vollständige Attestation Pipeline
- **Feature Branches**: Intermediate Signing mit Branch-Tags

### Artifact Management
- **SBOM Storage**: 30 Tage Retention in GitHub Artifacts
- **Signature Registry**: Persistent in OCI Registry
- **Provenance Data**: GitHub Attestation Store

## 📚 Weiterführende Informationen

- [SLSA Framework](https://slsa.dev/)
- [Sigstore Documentation](https://docs.sigstore.dev/)
- [SPDX Specification](https://spdx.github.io/spdx-spec/)
- [Docker Buildx Attestation](https://docs.docker.com/build/attestations/)
- [GitHub Attestation API](https://docs.github.com/en/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds)