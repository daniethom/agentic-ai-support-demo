#!/bin/bash

echo "🚀 Setting up Agentic AI Support Demo with Podman..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for Podman
if ! command_exists podman; then
    echo "❌ Podman is not installed. Please install Podman first."
    exit 1
fi

# Check for podman-compose (preferred) or docker-compose with podman
if command_exists podman-compose; then
    COMPOSE_CMD="podman-compose"
    echo "✅ Found podman-compose"
elif command_exists docker-compose; then
    # Set up Docker compatibility for podman
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    COMPOSE_CMD="docker-compose"
    echo "✅ Using docker-compose with Podman socket"
else
    echo "❌ Neither podman-compose nor docker-compose found."
    echo "📦 Installing podman-compose..."
    pip3 install podman-compose || {
        echo "❌ Failed to install podman-compose. Please install it manually:"
        echo "   pip3 install podman-compose"
        echo "   or"
        echo "   brew install podman-compose"
        exit 1
    }
    COMPOSE_CMD="podman-compose"
fi

# Check if Podman machine is running (for macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Detected macOS - checking Podman machine status..."
    
    # Check if podman machine exists and is running
    if ! podman machine list | grep -q "running"; then
        echo "🔧 Starting Podman machine..."
        
        # Try to start existing machine or create new one
        if podman machine list | grep -q "Currently defined machines"; then
            podman machine start
        else
            echo "📦 Creating new Podman machine..."
            podman machine init --cpus 4 --memory 8192 --disk-size 50
            podman machine start
        fi
        
        # Wait for machine to be ready
        echo "⏳ Waiting for Podman machine to be ready..."
        sleep 10
    else
        echo "✅ Podman machine is running"
    fi
fi

# Check if Podman is responding
if ! podman info >/dev/null 2>&1; then
    echo "❌ Podman is not responding. Please check your Podman installation."
    echo "💡 Try: podman machine start"
    exit 1
fi

echo "✅ Podman is ready"

# Create api directory structure if it doesn't exist
mkdir -p api

echo "📦 Building and starting all services with Podman..."

# Use the appropriate compose command
$COMPOSE_CMD up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to initialize..."
sleep 30

# Check if containers are running
echo "🔍 Checking container status..."
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check Ollama and pull model
echo "🤖 Setting up Ollama model..."
if podman ps | grep -q ollama-llm; then
    echo "📥 Pulling llama3 model (this may take a while)..."
    podman exec ollama-llm ollama pull llama3 || echo "⚠️  Model pull failed, trying to continue..."
else
    echo "⚠️  Ollama container not found, skipping model pull"
fi

# Wait a bit more for Ollama
sleep 10

# Setup Weaviate vector database
echo "🗄️  Setting up knowledge base..."
if podman ps | grep -q ai-support-demo; then
    podman exec ai-support-demo python rag-setup/ingest_data.py || echo "⚠️  Knowledge base setup had issues, but continuing..."
else
    echo "⚠️  Main app container not found, skipping knowledge base setup"
fi

# Test the setup
echo "🧪 Testing the setup..."

# Function to test endpoint with retries
test_endpoint() {
    local url=$1
    local service=$2
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" >/dev/null 2>&1; then
            echo "✅ $service is responding"
            return 0
        else
            echo "⏳ Attempt $attempt/$max_attempts: Waiting for $service..."
            sleep 5
            ((attempt++))
        fi
    done
    
    echo "⚠️  $service health check failed after $max_attempts attempts"
    return 1
}

# Test API endpoints
test_endpoint "http://localhost:8000/health" "API service"
test_endpoint "http://localhost:8000/account_status/CUST123" "Customer API"

# Test Weaviate
test_endpoint "http://localhost:8081/v1/meta" "Weaviate"

# Test Ollama
test_endpoint "http://localhost:11434/api/tags" "Ollama"

# Test Streamlit (may take longer to start)
echo "⏳ Waiting for Streamlit to be ready..."
sleep 15
test_endpoint "http://localhost:8501" "Streamlit"

echo ""
echo "✅ Setup complete!"
echo ""
echo "🌐 Access your demo at: http://localhost:8501"
echo "📊 Weaviate console: http://localhost:8081"
echo "🔧 API docs: http://localhost:8000/docs"
echo ""
echo "📝 To test, try asking: 'I'm customer CUST123 and my internet is slow'"
echo ""
echo "🛠️  Troubleshooting:"
echo "   - Check logs: $COMPOSE_CMD logs -f"
echo "   - Restart services: $COMPOSE_CMD restart"
echo "   - View container status: podman ps"
echo "   - Stop all: $COMPOSE_CMD down"
echo ""
echo "📋 Useful Podman commands:"
echo "   - podman ps                    # List running containers"
echo "   - podman logs [container]      # View container logs"
echo "   - podman exec -it [container] /bin/bash  # Access container shell"
echo "   - podman machine stop          # Stop Podman machine (macOS)"