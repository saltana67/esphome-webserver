# Pre-built Dev Image on GitHub Container Registry

No more npm registry timeouts! Dependencies are pre-installed in the cloud.

## How it works

1. GitHub Actions builds a Docker image with all npm dependencies pre-installed
2. Image is pushed to ghcr.io (GitHub Container Registry)
3. Locally, you just pull the image and mount your source code
4. Dependencies are symlinked from the image — no install needed

## Setup (one-time)

### 1. Add workflow to your repo

Copy `.github/workflows/build-dev-image.yml` to your repo.

### 2. Add Dockerfile

Copy `Dockerfile.dev-full` to `packages/captive-portal/`.

### 3. Trigger the build

Either:
- Push a change to `packages/captive-portal/package.json`
- Or manually trigger: Actions → Build Dev Image → Run workflow

### 4. Make package public (optional, for easier pulling)

Go to: github.com → Your repo → Packages → captive-portal-dev → Package settings → Change visibility → Public

Otherwise you'll need to `docker login ghcr.io` first.

## Local Usage

```bash
# Copy script to packages/captive-portal/
cp docker-ghcr.sh packages/captive-portal/
chmod +x packages/captive-portal/docker-ghcr.sh

# First run pulls the image automatically
./docker-ghcr.sh              # Production build

# Other modes
./docker-ghcr.sh --dev        # Dev server
./docker-ghcr.sh --shell      # Debug shell
./docker-ghcr.sh --pull       # Force pull latest
```

## File placement

```
esphome-webserver/
├── .github/
│   └── workflows/
│       └── build-dev-image.yml    # GitHub Actions workflow
└── packages/
    └── captive-portal/
        ├── Dockerfile.dev-full    # Image definition
        ├── docker-ghcr.sh         # Local run script
        ├── package.json
        ├── pnpm-lock.yaml
        └── ...
```

## When to rebuild the image

The workflow triggers automatically when these files change:
- `packages/captive-portal/package.json`
- `packages/captive-portal/pnpm-lock.yaml`
- `packages/captive-portal/Dockerfile.dev-full`

Or trigger manually from the Actions tab.

## Troubleshooting

**"Unable to pull image":**
```bash
# Login to GitHub Container Registry
docker login ghcr.io -u YOUR_GITHUB_USERNAME
# Enter a Personal Access Token with read:packages scope
```

**"node_modules symlink issues":**
```bash
# Remove local node_modules if it exists
rm -rf node_modules
./docker-ghcr.sh
```

**"Dependencies out of date":**
```bash
# Force pull latest image
./docker-ghcr.sh --pull
```
