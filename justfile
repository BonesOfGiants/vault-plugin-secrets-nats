# openbao-plugin-secrets-nats development tasks

# Set environment variables
export BAO_ADDR := "http://127.0.0.1:8200"
export BAO_TOKEN := "root"

# Default recipe - show available commands
default:
    @just --list

# Build the plugin (skipping problematic generate step)
build:
    go build -o openbao-plugin-secrets-nats ./cmd/openbao-plugin-secrets-nats/

# Clean build artifacts
clean:
    rm -f openbao-plugin-secrets-nats
    go clean -cache

# Start OpenBao in dev mode with plugin support
start-bao: build
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Kill any existing bao process
    pkill bao || true
    sleep 2
    
    # Create a clean plugin directory
    mkdir -p ./plugins
    cp openbao-plugin-secrets-nats ./plugins/
    
    echo "🚀 Starting OpenBao in dev mode..."
    bao server -dev \
        -dev-root-token-id=root \
        -dev-plugin-dir=$(pwd)/plugins \
        -log-level=info &
    
    echo "⏳ Waiting for OpenBao to start..."
    sleep 5
    
    # Wait for bao to be ready
    for i in {1..10}; do
        if bao status &>/dev/null; then
            break
        fi
        echo "Still waiting for OpenBao..."
        sleep 2
    done
    
    echo "✅ OpenBao started at $BAO_ADDR"
    echo "🔑 Root token: $BAO_TOKEN"

# Register and enable the NATS secrets plugin
enable-plugin: build
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Ensure plugin is in the plugins directory
    mkdir -p ./plugins
    cp openbao-plugin-secrets-nats ./plugins/
    
    SHA256SUM=$(sha256sum ./plugins/openbao-plugin-secrets-nats | cut -d' ' -f1)
    echo "📦 Plugin SHA256: $SHA256SUM"
    
    # Wait for bao to be ready
    echo "⏳ Waiting for OpenBao to be ready..."
    for i in {1..15}; do
        if bao status &>/dev/null; then
            echo "✅ OpenBao is ready"
            break
        fi
        if [ $i -eq 15 ]; then
            echo "❌ OpenBao not ready after 30 seconds"
            exit 1
        fi
        sleep 2
    done
    
    echo "📝 Registering plugin..."
    bao plugin register -sha256=${SHA256SUM} secret openbao-plugin-secrets-nats
    
    echo "🔌 Enabling plugin at nats-secrets/ ..."
    bao secrets enable -path=nats-secrets openbao-plugin-secrets-nats
    
    echo "✅ Plugin enabled! Check with: bao secrets list"

# start bao, enable plugin and create demo user
start:
    @just stop
    @just clean
    @just start-openbao
    @just enable-plugin
    @just login
    @just create-demo

# Login to OpenBao with root token
login:
    bao login ${BAO_TOKEN}   || echo "Already logged in or OpenBao not running"

# Stop OpenBao and clean up
stop:
    pkill bao || echo "No bao process found"
    @just clean

# Run tests
test:
    go test -v ./...

# Show plugin status and basic info
status:
    @echo "🔍 OpenBao Status:"
    @bao status || echo "OpenBao not running"
    @echo ""
    @echo "🔌 Secrets Engines:"
    @bao secrets list 2>/dev/null || echo "Cannot connect to bao"
    @echo ""
    @echo "📦 Plugin Binary:"
    @ls -la openbao-plugin-secrets-nats 2>/dev/null || echo "Plugin not built"

create-demo operator="demo-operator" account="demo-account" user="demo-user":
    set -euo pipefail
    echo "👑 Creating NATS operator: {{operator}}"
    bao write nats-secrets/issue/operator/{{operator}} @example_data/operator.json
    echo "🏢 Creating NATS account: {{account}} under operator: {{operator}}"
    bao write nats-secrets/issue/operator/{{operator}}/account/{{account}} @example_data/account.json
    echo "👤 Creating NATS user: {{user}} in account: {{account}}"
    bao write nats-secrets/issue/operator/{{operator}}/account/{{account}}/user/{{user}} @example_data/user.json

read-demo-user operator="demo-operator" account="demo-account" user="demo-user":
    set -euo pipefail
    echo "🔍 Reading NATS user with params: {{user}}"
    bao read nats-secrets/creds/operator/{{operator}}/account/{{account}}/user/{{user}} parameters='{"lobby_id": "123", "user_id": "456"}'