#!/bin/bash
# run_kcwi.sh

# Start Fake Screen (Xvfb)
Xvfb :99 -ac -screen 0 1280x1024x24 > /dev/null 2>&1 &
export DISPLAY=:99

# Start Network Bridge (Socat)
# This pipes the container's internal Bokeh port to the outside world
socat TCP-LISTEN:5006,fork,bind=0.0.0.0 TCP:127.0.0.1:5006 &

# Wait a moment for services to spin up
sleep 2

# Run the command passed by the user
exec conda run --no-capture-output -n kcwidrp "$@"