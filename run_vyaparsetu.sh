#!/usr/bin/env bash
set -e

# ==============================================================================
# VyaparSetu Local Development Launcher
# Starts Catalog (port 8000) and Pricing (port 8001) backend services.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 1. Resolve Python interpreters
if [ -z "$CATALOG_PYTHON" ]; then
    if [ -x ".venv-catalog/bin/python3" ]; then
        CATALOG_PYTHON=".venv-catalog/bin/python3"
    elif [ -x ".venv/bin/python3" ]; then
        CATALOG_PYTHON=".venv/bin/python3"
    else
        CATALOG_PYTHON="python3"
    fi
fi

if [ -z "$PRICING_PYTHON" ]; then
    if [ -x ".venv-pricing/bin/python3" ]; then
        PRICING_PYTHON=".venv-pricing/bin/python3"
    elif [ -x ".venv-catalog/bin/python3" ]; then
        PRICING_PYTHON=".venv-catalog/bin/python3"
    elif [ -x ".venv/bin/python3" ]; then
        PRICING_PYTHON=".venv/bin/python3"
    else
        PRICING_PYTHON="python3"
    fi
fi

# 2. Dependency checks
echo "============================================================"
echo "VyaparSetu — Checking backend environments..."
echo "============================================================"

if ! "$CATALOG_PYTHON" -c "import fastapi, uvicorn" >/dev/null 2>&1; then
    echo "ERROR: Catalog server dependencies (fastapi, uvicorn) missing in '$CATALOG_PYTHON'."
    echo "To fix: install via pip:"
    echo "    $CATALOG_PYTHON -m pip install -r requirements-catalog.txt"
    echo "Or set: CATALOG_PYTHON=/path/to/venv/bin/python3"
    exit 1
fi

if ! "$PRICING_PYTHON" -c "import fastapi, uvicorn" >/dev/null 2>&1 && ! "$PRICING_PYTHON" -c "import flask" >/dev/null 2>&1; then
    echo "ERROR: Pricing server dependencies (fastapi/flask, uvicorn) missing in '$PRICING_PYTHON'."
    echo "To fix: install via pip:"
    echo "    $PRICING_PYTHON -m pip install fastapi uvicorn"
    echo "Or set: PRICING_PYTHON=/path/to/venv/bin/python3"
    exit 1
fi

echo "Catalog Python: $CATALOG_PYTHON"
echo "Pricing Python: $PRICING_PYTHON"
echo ""

# 3. Clean process tracking & termination trap
CATALOG_PID=""
PRICING_PID=""

cleanup() {
    echo ""
    echo "Shutting down VyaparSetu backend services..."
    if [ -n "$CATALOG_PID" ] && kill -0 "$CATALOG_PID" 2>/dev/null; then
        kill "$CATALOG_PID" 2>/dev/null || true
    fi
    if [ -n "$PRICING_PID" ] && kill -0 "$PRICING_PID" 2>/dev/null; then
        kill "$PRICING_PID" 2>/dev/null || true
    fi
    wait "$CATALOG_PID" 2>/dev/null || true
    wait "$PRICING_PID" 2>/dev/null || true
    echo "All backend processes stopped cleanly."
}

trap cleanup INT TERM EXIT

# 4. Start Catalog backend on port 8000 (if port not already bound)
if lsof -i:8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "Port 8000 is already in use. Catalog server may already be running."
else
    echo "Starting Catalog backend on port 8000..."
    "$CATALOG_PYTHON" catalog_server.py &
    CATALOG_PID=$!
fi

# 5. Start Pricing backend on port 8001 (if port not already bound)
if lsof -i:8001 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "Port 8001 is already in use. Pricing server may already be running."
else
    echo "Starting Pricing backend on port 8001..."
    PRICING_API_PORT=8001 "$PRICING_PYTHON" pricing_api.py &
    PRICING_PID=$!
fi

# 6. Health check polling (up to 10 seconds)
echo "Waiting for health checks..."

wait_for_health() {
    local url=$1
    local name=$2
    local retries=20
    while [ $retries -gt 0 ]; do
        if curl -sf "$url" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.5
        retries=$((retries - 1))
    done
    return 1
}

CATALOG_STATUS="FAILED"
PRICING_STATUS="FAILED"

if wait_for_health "http://localhost:8000/health" "Catalog"; then
    CATALOG_STATUS="OK"
fi

if wait_for_health "http://localhost:8001/health" "Pricing"; then
    PRICING_STATUS="OK"
fi

echo ""
echo "============================================================"
echo "VyaparSetu Local Backend Services"
echo "============================================================"
echo "Catalog AI   : http://localhost:8000/health   [$CATALOG_STATUS]"
echo "Pricing API  : http://localhost:8001/health   [$PRICING_STATUS]"
echo ""
echo "API Endpoints:"
echo "  - Catalog: POST http://localhost:8000/api/generate-catalog"
echo "  - Pricing: POST http://localhost:8001/price"
echo ""
echo "Note:"
echo "  Opening http://localhost:8000/ or http://localhost:8001/ directly in a browser"
echo "  may return 404 because these are backend REST API services, not web pages."
echo ""
echo "============================================================"
echo "Next Steps: Run the Flutter Client"
echo "============================================================"
echo "Open another terminal window and run:"
echo "  flutter run"
echo ""
echo "Target options:"
echo "  - Web browser:     flutter run -d chrome"
echo "  - macOS Desktop:   flutter run -d macos"
echo "  - Android emulator: flutter run (automatically routes to 10.0.2.2:8000/8001)"
echo "============================================================"
echo "Press Ctrl+C in this terminal to stop both backend servers."
echo ""

# Keep running until user presses Ctrl+C
wait
