#!/bin/bash

SRC_DIR="$(pwd)/../../"
WORKING_DIR="/app"

DOCKER_ARGS=""

# -it: 
# -i, --interactive    Keep STDIN open even if not attached
# -t, --tty            Allocate a pseudo-TTY
# example: #docker run --name test -it debian
# The -it instructs Docker to allocate a pseudo-TTY connected to the container’s stdin; 
# creating an interactive bash shell in the container. 
# In the example, the bash shell is quit by entering exit 13. 
# This exit code is passed on to the caller of docker run, 
# and is recorded in the test container’s metadata.

DOCKER_ARGS="${DOCKER_ARGS} -it"


# --rm 
# Automatically remove the container when it exits

DOCKER_ARGS="${DOCKER_ARGS} --rm"


# --name mvn-package-sync2pg
# Assign a name to the container

DOCKER_ARGS="${DOCKER_ARGS} --name package-captive-portal"


# --network host
# If you use the host network mode for a container, 
# that container’s network stack is not isolated from the Docker host 
# (the container shares the host’s networking namespace), 
# and the container does not get its own IP-address allocated

DOCKER_ARGS="${DOCKER_ARGS} --network host"


# -v ${SRC_DIR}:${WORKING_DIR}
# --volume , -v	: Bind mount a volume
# example: $ docker  run  -v `pwd`:`pwd`
# The -v flag mounts the current working directory into the container

DOCKER_ARGS="${DOCKER_ARGS} -v ${SRC_DIR}:${WORKING_DIR}"


# -w ${WORKING_DIR}
# --workdir , -w 		Working directory inside the container
# example: $ docker  run -w /path/to/dir/

DOCKER_ARGS="${DOCKER_ARGS} -w ${WORKING_DIR}"

#
# docker image
#
IMAGE_NAME="node"  # node official
IMAGE_VERSION="24" #24: v24.12.0 (LTS), 22: v22.21.1 (LTS)
IMAGE_VARIANT="slim"  # slim (debian based), alpine

DOCKER_IMAGE="${IMAGE_NAME}${IMAGE_VERSION+:${IMAGE_VERSION}}${IMAGE_VARIANT+-${IMAGE_VARIANT}}"

#DOCKER_IMAGE="${IMAGE_NAME}:24-slim"
echo docker image: $DOCKER_IMAGE

MY_USER_ID=`id -u`
MY_USER_NAME=`id -un`
MY_GROUP_ID=`id -g`
MY_GROUP_NAME=`id -gn`

echo user: $MY_USER_NAME \($MY_USER_ID\) group: $MY_GROUP_NAME \($MY_GROUP_ID\)

USERADD_CMD="useradd -m -u ${MY_USER_ID} -g ${MY_GROUP_ID} -o -s /bin/bash ${MY_USER_NAME}"
GROUPADD_CMD="groupadd -g ${MY_GROUP_ID} -o ${MY_GROUP_NAME}"


# alpine special handling
#
if [[ $DOCKER_IMAGE == *alpine* ]]; then

	echo using addgroup and adduser
	# from https://wiki.alpinelinux.org/wiki/Setting_up_a_new_user
	#
	#	addgroup [-g GID] [-S] [USER] GROUP
	#
	#	Create a group or add a user to a group
	#
	#	    -g --gid GID    Group id
	#	    -S --system     Create a system group
	#

	GROUPADD_CMD="addgroup --gid ${MY_GROUP_ID} ${MY_GROUP_NAME}";

	#echo $GROUPADD_CMD;	

	#	adduser [OPTIONS] USER [GROUP]
	#
	#	Create new user, or add USER to GROUP
	#
	#     -h --home DIR           Home directory
	#     -g --gecos GECOS        GECOS field
	#     -s --shell SHELL        Login shell named SHELL by example /bin/bash
	#     -G --ingroup GRP        Group (by name)
	#     -S --system             Create a system user
	#     -D --disabled-password  Don't assign a password, so cannot login
	#     -H --no-create-home     Don't create home directory
	#     -u --uid UID            User id
	#     -k SKEL                 Skeleton directory (/etc/skel)
	
	USERADD_CMD="adduser --uid ${MY_USER_ID} --ingroup ${MY_GROUP_NAME} --shell /bin/bash --disabled-password ${MY_USER_NAME}";

	#echo $USERADD_CMD;
fi

echo add user command : ${USERADD_CMD}
echo add group command: ${GROUPADD_CMD} 

# comands to be executed in container
CON_CMD=""

# 
# special amazon linux handling
#
if [[ $DOCKER_IMAGE == *amazoncorretto* && $DOCKER_IMAGE != *debian* ]]; then

	echo "add /usr/sbin to PATH"
	CON_CMD="export PATH=\"/usr/sbin:\${PATH}\"";

	echo "install shadowutils for useradd and groupdd"
	CON_CMD="${CON_CMD} && yum -y install shadow-utils";
	
	echo "install utils-linux for su"
	CON_CMD="${CON_CMD} && yum -y install util-linux";
	
	CON_CMD="${CON_CMD} && ";
fi

#CON_CMD="${CON_CMD}ls -la /usr/sbin && ls -la /bin && which useradd && which groupadd && "

CON_CMD="${CON_CMD}${GROUPADD_CMD}"
CON_CMD="${CON_CMD} && ${USERADD_CMD}"
CON_CMD="${CON_CMD} && corepack enable && apt-get update -y && apt-get install -y xxd"
#CON_CMD="${CON_CMD} && su ${MY_USER_NAME} -c 'pwd && ls -la && cd packages/captive-portal && pwd && ls -la'"
CON_CMD="${CON_CMD} && su ${MY_USER_NAME} -c 'pwd && ls -la && cd packages/captive-portal && pwd && ls -la && pnpm install && npm run build && BROWSER=none npm run start'"

CMD="docker run ${DOCKER_ARGS} ${DOCKER_IMAGE} /bin/bash -c \"${CON_CMD}\""
echo $CMD

eval $CMD
