#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Image from GitHub Container Registry
IMAGE="ghcr.io/saltana67/esphome-webserver/captive-portal-dev:latest"

# User mapping - files created will be owned by current user
MY_USER_ID=$(id -u)
MY_GROUP_ID=$(id -g)

# Parse command line arguments
MODE="build"
PULL="auto"

while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            MODE="dev"
            shift
            ;;
        --shell)
            MODE="shell"
            shift
            ;;
        --pull)
            PULL="always"
            shift
            ;;
        --no-pull)
            PULL="never"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Uses pre-built image from ghcr.io with dependencies pre-installed."
            echo "No npm/pnpm install needed - just pull and build!"
            echo ""
            echo "Options:"
            echo "  --dev       Run dev server with hot reload"
            echo "  --shell     Open interactive shell"
            echo "  --pull      Always pull latest image"
            echo "  --no-pull   Never pull (use cached)"
            echo "  --help      Show this help"
            echo ""
            echo "Examples:"
            echo "  $0              # Production build"
            echo "  $0 --dev        # Dev server"
            echo "  $0 --shell      # Debug shell"
            echo "  $0 --pull       # Force pull latest image"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage"
            exit 1
            ;;
    esac
done

# Pull image if needed
if [[ "$PULL" == "always" ]]; then
    echo "Pulling latest image..."
    docker pull "$IMAGE"
elif [[ "$PULL" == "auto" ]]; then
    if ! docker image inspect "$IMAGE" &>/dev/null; then
        echo "Image not found locally, pulling..."
        docker pull "$IMAGE"
    fi
fi

# Determine command to run
# Link pre-installed node_modules from /deps to current dir
LINK_CMD="ln -sfn /deps/node_modules ."

case $MODE in
    build)
        RUN_CMD="${LINK_CMD} && npm run build"
        ;;
    dev)
        RUN_CMD="${LINK_CMD} && BROWSER=none npm run dev"
        ;;
    shell)
        RUN_CMD="${LINK_CMD} && bash"
        ;;
esac

echo "Image: $IMAGE"
echo "User: $(id -un) ($MY_USER_ID:$MY_GROUP_ID)"
echo "Mode: $MODE"
echo ""

docker run -it --rm \
    --name captive-portal-build \
    --network host \
    --user ${MY_USER_ID}:${MY_GROUP_ID} \
    -v "${SRC_DIR}:/app" \
    -w /app/packages/captive-portal \
    "$IMAGE" \
    bash -c "${RUN_CMD}"
