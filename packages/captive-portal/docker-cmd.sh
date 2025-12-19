#!/bin/bash

SRC_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
WORKING_DIR="/app"

DOCKER_ARGS="-it --rm --name package-captive-portal --network host"
DOCKER_ARGS="${DOCKER_ARGS} -v ${SRC_DIR}:${WORKING_DIR}"
DOCKER_ARGS="${DOCKER_ARGS} -w ${WORKING_DIR}/packages/captive-portal"

# Node 22 LTS - stable choice
DOCKER_IMAGE="node:22-slim"

MY_USER_ID=$(id -u)
MY_USER_NAME=$(id -un)
MY_GROUP_ID=$(id -g)
MY_GROUP_NAME=$(id -gn)

echo "Docker image: $DOCKER_IMAGE"
echo "User: $MY_USER_NAME ($MY_USER_ID) Group: $MY_GROUP_NAME ($MY_GROUP_ID)"

SETUP_CMD="groupadd -g ${MY_GROUP_ID} -o ${MY_GROUP_NAME}"
SETUP_CMD="${SETUP_CMD} && useradd -m -u ${MY_USER_ID} -g ${MY_GROUP_ID} -o -s /bin/bash ${MY_USER_NAME}"
SETUP_CMD="${SETUP_CMD} && apt-get update -y && apt-get install -y xxd"
SETUP_CMD="${SETUP_CMD} && corepack enable"

# pnpm with retry and increased timeout
BUILD_CMD="pnpm config set fetch-timeout 120000"
BUILD_CMD="${BUILD_CMD} && pnpm install --prefer-offline || pnpm install"
BUILD_CMD="${BUILD_CMD} && npm run build"

# Parse command line arguments
MODE="build"
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
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dev|--shell]"
            exit 1
            ;;
    esac
done

case $MODE in
    dev)
        BUILD_CMD="${BUILD_CMD} && BROWSER=none npm run dev"
        ;;
    shell)
        BUILD_CMD="bash"
        ;;
esac

CMD="docker run ${DOCKER_ARGS} ${DOCKER_IMAGE} /bin/bash -c '${SETUP_CMD} && su ${MY_USER_NAME} -c \"${BUILD_CMD}\"'"

echo "$CMD"
eval "$CMD"
