#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
IMAGE_NAME="captive-portal-dev"

MY_USER_ID=$(id -u)
MY_USER_NAME=$(id -un)
MY_GROUP_ID=$(id -g)

# Parse command line arguments
ACTION="run"
MODE="build"
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-image)
            ACTION="build-image"
            shift
            ;;
        --dev)
            MODE="dev"
            shift
            ;;
        --shell)
            MODE="shell"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --build-image   Build/rebuild the Docker image"
            echo "  --dev           Run dev server with hot reload"
            echo "  --shell         Open interactive shell"
            echo "  --help          Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 --build-image     # First time: build the image"
            echo "  $0                   # Run production build"
            echo "  $0 --dev             # Run dev server"
            echo "  $0 --shell           # Open shell for debugging"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage"
            exit 1
            ;;
    esac
done

# Build image if requested or if it doesn't exist
if [[ "$ACTION" == "build-image" ]] || ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "Building Docker image: $IMAGE_NAME"
    docker build -f "${SCRIPT_DIR}/Dockerfile.dev" \
        --build-arg USER_ID=${MY_USER_ID} \
        --build-arg GROUP_ID=${MY_GROUP_ID} \
        --build-arg USER_NAME=${MY_USER_NAME} \
        -t ${IMAGE_NAME} \
        "${SCRIPT_DIR}"
    
    if [[ "$ACTION" == "build-image" ]]; then
        echo "Image built successfully: $IMAGE_NAME"
        exit 0
    fi
fi

# Determine command to run
case $MODE in
    build)
        RUN_CMD="pnpm install && npm run build"
        ;;
    dev)
        RUN_CMD="pnpm install && BROWSER=none npm run dev"
        ;;
    shell)
        RUN_CMD="bash"
        ;;
esac

echo "Docker image: $IMAGE_NAME"
echo "User: $MY_USER_NAME ($MY_USER_ID)"
echo "Mode: $MODE"
echo ""

docker run -it --rm \
    --name package-captive-portal \
    --network host \
    --user ${MY_USER_ID}:${MY_GROUP_ID} \
    -v "${SRC_DIR}:/app" \
    -w /app/packages/captive-portal \
    ${IMAGE_NAME} \
    bash -c "${RUN_CMD}"
