#!/bin/bash

echo "🚀 Setting up Agentic AI Support Demo..."

# Create api directory structure
mkdir -p api

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Build and start all services
echo "📦 Building and starting all services..."
docker-compose up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to initialize..."
sleep 30

# Check Ollama and pull model
echo "🤖 Setting up Ollama model..."
docker exec ollama-llm ollama pull llama3 || echo "⚠️  Model pull failed, trying to continue..."

# Wait a bit more for Ollama
sleep 10

# Setup Weaviate vector database
echo "🗄️  Setting up knowledge base..."
docker exec ai-support-demo python rag-setup/ingest_data.py || echo "⚠️  Knowledge base setup had issues, but continuing..."

# Test the setup
echo "🧪 Testing the setup..."

# Test API endpoints
echo "Testing API endpoints..."
curl -f http://localhost:8000/health || echo "⚠️  API health check failed"
curl -f http://localhost:8000/account_status/CUST123 || echo "⚠️  Customer API test failed"

# Test Weaviate
curl -f http://localhost:8081/v1/meta || echo "⚠️  Weaviate health check failed"

# Test Ollama
curl -f http://localhost:11434/api/tags || echo "⚠️  Ollama health check failed"

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
echo "   - Check logs: docker-compose logs -f"
echo "   - Restart services: docker-compose restart"
echo "   - View individual service logs: docker logs [container-name]"