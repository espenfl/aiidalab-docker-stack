#!/bin/bash

set -x

docker run --init --user 0 -ti aiidalab-docker-stack:discover /bin/bash

# login as scientist
#docker run --init --user scientist -ti mc-docker-stack:master /bin/bash

#EOF
