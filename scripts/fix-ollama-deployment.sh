#!/bin/bash

echo "🔧 Fixing Ollama Permissions Issue"
echo "=================================="

# Check if deployment exists
if ! oc get deployment ollama -n agentic-ai-demo >/dev/null 2>&1; then
    echo "❌ Ollama deployment not found. Please deploy first."
    exit 1
fi

echo "🛑 Stopping current Ollama deployment..."
oc scale deployment ollama --replicas=0 -n agentic-ai-demo

echo "⏳ Waiting for pod to terminate..."
sleep 10

echo "🔧 Updating Ollama deployment with proper permissions..."

# Create a fixed Ollama deployment
cat > ollama-fix.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: agentic-ai-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ollama
  template:
    metadata:
      labels:
        app: ollama
    spec:
      # Add security context for proper permissions
      securityContext:
        runAsUser: 0  # Run as root to avoid permission issues
        runAsGroup: 0
        fsGroup: 0
      containers:
      - name: ollama
        image: ollama/ollama
        ports:
        - containerPort: 11434
        env:
        - name: OLLAMA_HOST
          value: "0.0.0.0"
        - name: OLLAMA_DATA_DIR
          value: "/ollama-data"
        - name: OLLAMA_MODELS
          value: "/ollama-data/models"
        # Memory-optimized settings
        - name: OLLAMA_NUM_PARALLEL
          value: "1"
        - name: OLLAMA_MAX_LOADED_MODELS
          value: "1"
        - name: OLLAMA_FLASH_ATTENTION
          value: "1"
        # Create directories and start Ollama
        command: ["/bin/bash"]
        args:
        - -c
        - |
          echo "🚀 Starting Ollama with proper permissions..."
          
          # Create necessary directories with proper permissions
          mkdir -p /ollama-data/.ollama
          mkdir -p /ollama-data/models
          chmod -R 755 /ollama-data
          
          # Set OLLAMA_HOME to writable directory
          export OLLAMA_HOME=/ollama-data/.ollama
          
          echo "📁 Created directories:"
          ls -la /ollama-data/
          
          # Start Ollama server
          echo "🤖 Starting Ollama server..."
          exec ollama serve
        resources:
          requests:
            memory: "1Gi"
            cpu: "300m"
          limits:
            memory: "2Gi"
            cpu: "800m"
        volumeMounts:
        - name: ollama-data
          mountPath: /ollama-data
        readinessProbe:
          httpGet:
            path: /api/tags
            port: 11434
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 6
        livenessProbe:
          httpGet:
            path: /api/tags
            port: 11434
          initialDelaySeconds: 120
          periodSeconds: 30
          timeoutSeconds: 10
          failureThreshold: 3
      volumes:
      - name: ollama-data
        emptyDir:
          sizeLimit: 8Gi
EOF

# Apply the fix
echo "📦 Applying fixed Ollama deployment..."
oc apply -f ollama-fix.yaml

# Clean up temp file
rm ollama-fix.yaml

echo "⏳ Waiting for Ollama to start with fixed permissions..."
if oc rollout status deployment/ollama -n agentic-ai-demo --timeout=300s; then
    echo "✅ Ollama is now running with proper permissions!"
    
    # Wait for Ollama to be ready
    echo "⏳ Waiting for Ollama API to be ready..."
    for i in {1..20}; do
        if oc exec deployment/ollama -n agentic-ai-demo -- curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
            echo "✅ Ollama API is ready!"
            break
        else
            echo "   Waiting for Ollama API... ($i/20)"
            sleep 10
        fi
    done
    
    # Try to pull a small model
    echo "🤖 Attempting to pull a small model..."
    echo "   This will download in the background (may take 5-10 minutes)"
    
    # Pull tinyllama (smallest available model ~637MB)
    oc exec deployment/ollama -n agentic-ai-demo -- ollama pull tinyllama &
    PULL_PID=$!
    
    echo "✅ Model download started in background"
    echo ""
    echo "📊 Current Status:"
    oc get pods -n agentic-ai-demo -l app=ollama
    
    echo ""
    echo "🔍 To check model download progress:"
    echo "   oc logs -f deployment/ollama -n agentic-ai-demo"
    
    echo ""
    echo "🧪 To test when ready:"
    echo "   oc exec deployment/ollama -n agentic-ai-demo -- ollama list"
    
else
    echo "⚠️  Ollama deployment still having issues. Let's check the logs:"
    echo ""
    echo "🔍 Recent pod logs:"
    oc logs deployment/ollama -n agentic-ai-demo --tail=20
    
    echo ""
    echo "🛠️  Alternative solutions:"
    echo "1. Try running without Ollama (remove LLM features temporarily)"
    echo "2. Run Ollama locally on your Mac instead of in CRC"
    echo "3. Use a different base image"
fi

echo ""
echo "💡 Troubleshooting commands:"
echo "   Check logs: oc logs -f deployment/ollama -n agentic-ai-demo"
echo "   Check pod: oc describe pod -l app=ollama -n agentic-ai-demo"
echo "   Test API: oc exec deployment/ollama -n agentic-ai-demo -- curl http://localhost:11434/api/tags"