# Container Images Build System - AI Agent Guide

## Project Overview

This is an automated container image build pipeline that continuously provides **production-ready, security-hardened container images** with weekly rebuilds to ensure latest security patches. Every top-level directory (except `.github/`) represents a standalone container image to build and publish to Docker Hub.

**Goal**: Build images that achieve Docker Hub Scout "A" rating with comprehensive supply chain security (SLSA provenance, SBOMs, Cosign signatures).

## Architecture Pattern: Image-per-Directory

```
container-images/
├── etcd-client/          # Each directory = one container image
│   ├── Containerfile     # Build definition (required)
│   └── image.yml         # Metadata & config (required)
├── network-debug/
│   ├── Containerfile
│   └── image.yml
├── thanos/
│   ├── Containerfile
│   └── image.yml
└── .github/
    └── workflows/
        └── build-images.yml  # Discovers & builds all images
```

## Adding a New Container Image

**Copy-paste workflow** - clone an existing image directory:

```bash
# 1. Copy from similar existing image
cp -r etcd-client/ my-new-image/

# 2. Edit image.yml with new metadata
cd my-new-image/
vim image.yml  # Update name, version, description

# 3. Modify Containerfile for your use case
vim Containerfile

# 4. Commit - workflow auto-discovers on push
git add .
git commit -m "feat: add my-new-image container"
git push
```

**Critical**: Both `Containerfile` and `image.yml` must exist in the directory root for auto-discovery.

## The `image.yml` Schema

This YAML file drives build configuration and metadata:

```yaml
name: etcd-client                    # Container name (becomes hansfischer/etcd-client)
version: 3.5.21                      # Version tag (use upstream version)
description: "Short description"     # OCI image description
registry: hansfischer                # Docker Hub username
maintainer: Hans Fischer             # Image maintainer
platforms:                           # Multi-arch builds
  - linux/amd64
  - linux/arm64
```

**Version field is passed as `ETCD_VERSION` and `IMAGE_VERSION` build args** - use in Containerfile:

```dockerfile
ARG ETCD_VERSION
ARG IMAGE_VERSION
ENV ETCD_VER=v${ETCD_VERSION}
```

## Containerfile Patterns

### Multi-arch Pattern (see `etcd-client/Containerfile`)
```dockerfile
ARG TARGETARCH  # Auto-provided by buildx (amd64/arm64)
RUN curl -L ${URL}/etcd-${ETCD_VER}-linux-${TARGETARCH}.tar.gz -o /tmp/etcd.tar.gz
```

### Security Hardening Baseline
```dockerfile
FROM ubuntu:24.04  # Use specific versions, not :latest

# Always upgrade packages for security patches
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*  # Reduce image size

# Use non-root user (see thanos/Containerfile)
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser
```

### Labels for OCI Compliance
```dockerfile
LABEL org.opencontainers.image.title="My Image" \
      org.opencontainers.image.description="..." \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.source="https://github.com/guided-traffic/container-images"
```

## Build Workflow Behavior

### Automatic Triggers
- **Weekly rebuild**: Every Sunday 20:00 UTC - rebuilds ALL images with latest security patches
- **On commit**: Rebuilds only changed image directories when `Containerfile` or `image.yml` modified
- **Manual dispatch**: `workflow_dispatch` with options:
  - `force_rebuild: true` - rebuild all images
  - `specific_image: "etcd-client"` - rebuild only one image

### Build Pipeline Stages
1. **Discovery**: Scans for directories with both `Containerfile` + `image.yml`
2. **Multi-arch build**: Uses Docker Buildx for `linux/amd64` and `linux/arm64`
3. **Security scanning**: Trivy vulnerability scan → GitHub Security tab
4. **Supply chain security**:
   - SBOM generation (SPDX, CycloneDX, Syft formats)
   - Cosign keyless signing (image + SBOM attestation)
   - SLSA provenance attestation
5. **Publish**: Push to Docker Hub with public visibility

### Tagging Strategy
```
hansfischer/etcd-client:3.5.21    # Version from image.yml
hansfischer/etcd-client:latest    # Only on main branch
hansfischer/etcd-client:develop   # On develop branch
hansfischer/etcd-client:pr-42     # On pull requests
```

## Security & Supply Chain

**All images include**:
- **Trivy SARIF reports** → GitHub Security tab for vulnerability tracking
- **SBOM artifacts** uploaded as workflow artifacts (30-day retention)
- **Cosign signatures** verifiable via:
  ```bash
  cosign verify hansfischer/etcd-client@sha256:...
  cosign verify-attestation hansfischer/etcd-client@sha256:...
  ```
- **SLSA provenance** for build integrity verification

**Docker Hub Scout**: Target "A" rating - minimize CVEs, use minimal base images, keep packages updated.

## Dependency Management with Renovate

`renovate.json` auto-updates:
- Base image versions (`ubuntu:24.04` → newer)
- Tool versions in `image.yml` (e.g., `etcd-io/etcd` releases)
- GitHub Actions versions in workflows

**Custom regex managers** track:
- `version:` field in `image.yml` linked to GitHub releases
- `FROM` directives in Containerfiles

PRs labeled `dependencies` + `renovate` are auto-created weekdays before 6am Europe/Berlin.

## Key Files Reference

| File | Purpose |
|------|---------|
| `*/Containerfile` | Docker build definition (multi-stage, multi-arch aware) |
| `*/image.yml` | Image metadata, versioning, platform targets |
| `.github/workflows/build-images.yml` | CI/CD orchestration (discover → build → scan → sign) |
| `renovate.json` | Automated dependency updates |

## Common Development Tasks

### Test a Containerfile locally
```bash
cd etcd-client/
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg ETCD_VERSION=3.5.21 \
  --build-arg IMAGE_VERSION=3.5.21 \
  -t hansfischer/etcd-client:test .
```

### Trigger specific image rebuild
```bash
# Via GitHub UI: Actions → Build Container Images → Run workflow
# Set "specific_image" input to directory name (e.g., "etcd-client")
```

### Check security scan results
Navigate to **Security tab → Code scanning alerts** for Trivy findings per image.

### Update image version
```bash
# Edit image.yml - Renovate auto-detects or manual edit
cd etcd-client/
sed -i '' 's/version: .*/version: 3.5.22/' image.yml
git commit -am "chore: bump etcd-client to 3.5.22"
git push  # Auto-triggers rebuild
```

## Non-Obvious Behaviors

1. **Build args auto-injection**: Workflow passes `ETCD_VERSION` and `IMAGE_VERSION` from `image.yml → version` field
2. **PR builds don't push**: Pull requests build but skip push/signing to prevent polluting registry
3. **Private → Public enforcement**: After push, workflow explicitly sets Docker Hub repo visibility to public via API
4. **Docker credentials in security steps**: SBOM/Cosign steps require `DOCKER_CONFIG` env for private repo access during signing
5. **Matrix parallelization**: All discovered images build concurrently (fail-fast: false)

## Conventions Different from Standard Practices

- **Use `image.yml` not Dockerfile labels**: Version/metadata defined in YAML, injected as build args
- **Directory name ≠ image name**: Directory can differ from `image.yml → name` field
- **Weekly rebuilds mandatory**: Not just on-commit - ensures security patches even with no code changes
- **Multi-format SBOMs**: Generate SPDX, CycloneDX, AND Syft native (most tools only do one)
- **Keyless Cosign**: Uses `COSIGN_EXPERIMENTAL=1` for GitHub OIDC signing (no keys to manage)

## Debugging Build Failures

Check workflow run summaries - each build generates:
- 🏷️ Generated tags list
- 🔒 Supply chain attestation status
- 🔍 Verification commands for manual inspection

For Trivy failures: Review SARIF upload step - security-events write permission required.
