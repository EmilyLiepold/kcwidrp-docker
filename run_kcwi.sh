#!/bin/bash
# run_kcwi.sh

# Start Fake Screen (Xvfb)
Xvfb :99 -ac -screen 0 1280x1024x24 > /dev/null 2>&1 &
export DISPLAY=:99

# Start Bokeh server in the background
# KCWI DRP's StartBokeh primitive expects a running bokeh server to connect to
# --session-token-expiration=86400 sets token expiration to 24 hours
conda run --no-capture-output -n kcwidrp bokeh serve \
    --allow-websocket-origin="*" \
    --port=5006 \
    --session-token-expiration=86400 &
BOKEH_PID=$!

# Wait for Bokeh server to be ready
echo "Waiting for Bokeh server to start..."
for i in {1..30}; do
    if curl -s http://127.0.0.1:5006/ > /dev/null 2>&1; then
        echo "Bokeh server is ready on port 5006"
        echo ">>> View plots at: http://localhost:5006/?bokeh-session-id=kcwi <<<"
        break
    fi
    sleep 1
done

# Run the command passed by the user
exec conda run --no-capture-output -n kcwidrp "$@"