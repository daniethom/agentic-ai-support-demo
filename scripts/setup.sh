#!/bin/bash

echo "🚀 Setting up Agentic AI Support Demo..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect container runtime and compose tool
CONTAINER_RUNTIME=""
COMPOSE_CMD=""
COMPOSE_FILE="docker-compose.yaml"

# Check for Podman first (since you're using it)
if command_exists podman; then
    CONTAINER_RUNTIME="podman"
    
    # Check for podman-compose
    if command_exists podman-compose; then
        COMPOSE_CMD="podman-compose"
        COMPOSE_FILE="docker-compose-podman.yaml"
        echo "✅ Using Podman with podman-compose"
    elif command_exists docker-compose; then
        # Set up Docker compatibility socket for podman
        export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
        COMPOSE_CMD="docker-compose"
        COMPOSE_FILE="docker-compose-podman.yaml"
        echo "✅ Using Podman with docker-compose compatibility"
    else
        echo "📦 Installing podman-compose..."
        pip3 install podman-compose || {
            echo "❌ Failed to install podman-compose."
            echo "💡 Please install it manually:"
            echo "   pip3 install podman-compose"
            echo "   or"
            echo "   brew install podman-compose"
            exit 1
        }
        COMPOSE_CMD="podman-compose"
        COMPOSE_FILE="docker-compose-podman.yaml"
    fi
    
    # Special handling for macOS Podman
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🍎 macOS detected - checking Podman machine..."
        
        if ! podman machine list 2>/dev/null | grep -q "running"; then
            echo "🔧 Starting Podman machine..."
            
            if podman machine list 2>/dev/null | grep -q "Currently defined machines" && podman machine list 2>/dev/null | grep -q "."; then
                podman machine start || {
                    echo "❌ Failed to start Podman machine"
                    echo "💡 Try: podman machine init && podman machine start"
                    exit 1
                }
            else
                echo "📦 Creating new Podman machine..."
                podman machine init --cpus 4 --memory 8192 --disk-size 50
                podman machine start
            fi
            
            echo "⏳ Waiting for Podman machine to be ready..."
            sleep 15
        fi
    fi
    
    # Check if Podman is responding
    if ! podman info >/dev/null 2>&1; then
        echo "❌ Podman is not responding."
        echo "💡 Try running: podman machine start"
        exit 1
    fi

# Fall back to Docker
elif command_exists docker; then
    CONTAINER_RUNTIME="docker"
    
    if command_exists docker-compose; then
        COMPOSE_CMD="docker-compose"
        echo "✅ Using Docker with docker-compose"
    else
        echo "❌ docker-compose not found."
        echo "💡 Please install docker-compose or use 'docker compose' (if available)"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker is not running. Please start Docker first."
        exit 1
    fi

else
    echo "❌ Neither Docker nor Podman found."
    echo "💡 Please install either:"
    echo "   - Docker Desktop: https://www.docker.com/products/docker-desktop"
    echo "   - Podman: https://podman.io/getting-started/installation"
    exit 1
fi

echo "🐳 Using $CONTAINER_RUNTIME as container runtime"

# Create api directory structure if it doesn't exist
mkdir -p api

# Use the appropriate compose file and command
echo "📦 Building and starting services with $COMPOSE_CMD..."
if [[ "$COMPOSE_FILE" == "docker-compose-podman.yaml" ]] && [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "📄 Using standard docker-compose.yaml (Podman should be compatible)"
    COMPOSE_FILE="docker-compose.yaml"
fi

$COMPOSE_CMD -f $COMPOSE_FILE up --build -d

# Wait for services to initialize
echo "⏳ Waiting for services to initialize..."
sleep 30

# Check container status
echo "🔍 Checking container status..."
$CONTAINER_RUNTIME ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || $CONTAINER_RUNTIME ps

# Setup Ollama model
echo "🤖 Setting up Ollama model..."
OLLAMA_CONTAINER=$($CONTAINER_RUNTIME ps --filter "name=ollama" --format "{{.Names}}" | head -1)
if [[ -n "$OLLAMA_CONTAINER" ]]; then
    echo "📥 Pulling llama3 model (this may take several minutes)..."
    $CONTAINER_RUNTIME exec $OLLAMA_CONTAINER ollama pull llama3 || echo "⚠️  Model pull failed, trying to continue..."
else
    echo "⚠️  Ollama container not found"
fi

# Wait for Ollama to be ready
sleep 10

# Setup knowledge base
echo "🗄️  Setting up knowledge base..."
APP_CONTAINER=$($CONTAINER_RUNTIME ps --filter "name=ai-support-demo" --format "{{.Names}}" | head -1)
if [[ -n "$APP_CONTAINER" ]]; then
    $CONTAINER_RUNTIME exec $APP_CONTAINER python rag-setup/ingest_data.py || echo "⚠️  Knowledge base setup had issues, continuing..."
else
    echo "⚠️  App container not found"
fi

# Test the setup with retries
echo "🧪 Testing the setup..."

test_endpoint() {
    local url=$1
    local service=$2
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" >/dev/null 2>&1; then
            echo "✅ $service is healthy"
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                echo "⏳ $service not ready, retrying in 5 seconds... ($attempt/$max_attempts)"
                sleep 5
            fi
            ((attempt++))
        fi
    done
    
    echo "⚠️  $service health check failed"
    return 1
}

# Test services
test_endpoint "http://localhost:8000/health" "API service"
test_endpoint "http://localhost:8081/v1/meta" "Weaviate"
test_endpoint "http://localhost:11434/api/tags" "Ollama"

# Test Streamlit (may take longer)
echo "⏳ Waiting for Streamlit to start..."
sleep 10
test_endpoint "http://localhost:8501" "Streamlit app"

echo ""
echo "✅ Setup complete!"
echo ""
echo "🌐 Access your demo at: http://localhost:8501"
echo "📊 Weaviate console: http://localhost:8081"
echo "🔧 API docs: http://localhost:8000/docs"
echo ""
echo "📝 To test, try asking: 'I'm customer CUST123 and my internet is slow'"
echo ""
echo "🛠️  Troubleshooting ($CONTAINER_RUNTIME):"
echo "   - View logs: $COMPOSE_CMD -f $COMPOSE_FILE logs -f"
echo "   - Restart: $COMPOSE_CMD -f $COMPOSE_FILE restart"
echo "   - Stop all: $COMPOSE_CMD -f $COMPOSE_FILE down"
echo "   - Container status: $CONTAINER_RUNTIME ps"
echo "   - Individual logs: $CONTAINER_RUNTIME logs [container-name]"

if [[ "$CONTAINER_RUNTIME" == "podman" ]]; then
    echo ""
    echo "🐳 Podman-specific commands:"
    echo "   - podman machine status    # Check Podman machine"
    echo "   - podman machine stop      # Stop Podman machine"
    echo "   - podman system prune      # Clean up resources"
fi