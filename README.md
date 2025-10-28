# Container Images

**Production-ready, security-hardened container images with automated weekly rebuilds.**

## 🎯 Purpose

This repository provides continuously updated container images that are:
- **Security-first**: Weekly automated rebuilds ensure the latest security patches
- **Production-ready**: Targeting Docker Hub Scout "A" rating with minimal CVEs
- **Supply-chain secured**: Every image includes SLSA provenance, SBOMs, and Cosign signatures
- **Multi-architecture**: Built for `linux/amd64` and `linux/arm64`

## 📦 Available Images

All images are published to Docker Hub: **[hansfischer on Docker Hub](https://hub.docker.com/u/hansfischer)**

| Image | Description | Docker Hub |
|-------|-------------|------------|
| `etcd-client` | Ubuntu minimal with etcd client tools | [hansfischer/etcd-client](https://hub.docker.com/r/hansfischer/etcd-client) |
| `network-debug` | Network debugging toolkit | [hansfischer/network-debug](https://hub.docker.com/r/hansfischer/network-debug) |
| `thanos` | Thanos monitoring on Debian slim | [hansfischer/thanos](https://hub.docker.com/r/hansfischer/thanos) |

## 🚀 Quick Start

```bash
# Pull an image
docker pull hansfischer/etcd-client:latest

# Verify signature (requires cosign)
cosign verify hansfischer/etcd-client:latest

# View SBOM
docker sbom hansfischer/etcd-client:latest
```

## 🔒 Security

- **Automated scanning**: Trivy vulnerability scans on every build
- **Weekly rebuilds**: Every Sunday at 20:00 UTC to apply latest patches
- **Supply chain attestation**: SLSA provenance, SBOMs (SPDX, CycloneDX), Cosign signatures
- **Transparency**: Security scan results available in the [Security tab](../../security/code-scanning)

## 🛠️ Contributing

Want to add a new image? Simply:
1. Copy an existing image directory (e.g., `cp -r etcd-client/ my-image/`)
2. Edit `image.yml` with your metadata
3. Modify `Containerfile` for your use case
4. Commit and push - the CI/CD pipeline auto-discovers and builds it

See [`.github/copilot-instructions.md`](.github/copilot-instructions.md) for detailed development guide.

## 📋 Build Status

Images are automatically built and published on:
- Every commit affecting `Containerfile` or `image.yml`
- Weekly schedule (Sunday 20:00 UTC)
- Manual workflow dispatch

## 📄 License

See [LICENSE](LICENSE) for details.
