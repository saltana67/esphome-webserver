# Docker Build Scripts for Captive Portal

Two approaches for building the captive portal:

## Option 1: docker-cmd.sh (Simple, no pre-built image)

Runs setup every time. Slower but simpler.

```bash
# Production build
./docker-cmd.sh

# Dev server with hot reload
./docker-cmd.sh --dev

# Interactive shell
./docker-cmd.sh --shell
```

## Option 2: docker-image.sh (Pre-built image, faster)

Builds a Docker image once with all tools. Faster for repeated builds.

```bash
# First time: build the image
./docker-image.sh --build-image

# Production build (fast)
./docker-image.sh

# Dev server
./docker-image.sh --dev

# Interactive shell
./docker-image.sh --shell
```

## File placement

Place these files in `packages/captive-portal/`:

```
esphome-webserver/
├── packages/
│   └── captive-portal/
│       ├── docker-cmd.sh        # Option 1
│       ├── Dockerfile.dev       # Option 2
│       ├── docker-image.sh      # Option 2
│       ├── vite.config.ts
│       ├── package.json
│       └── ...
```

## Troubleshooting

**Registry timeouts:**
Both scripts set `fetch-timeout 120000` (2 min). If still timing out:
```bash
# In shell mode
pnpm config set fetch-timeout 300000  # 5 min
pnpm install
```

**Permission issues:**
Scripts map your local user into the container. If issues persist:
```bash
# Check ownership
ls -la _static/

# Fix if needed
sudo chown -R $(id -u):$(id -g) _static/
```

**Rebuild image after changes:**
```bash
./docker-image.sh --build-image
```
