#!/bin/bash

echo "🔒 Fixing OpenShift Security Context Constraints"
echo "=============================================="

echo "🧹 Cleaning up existing deployment..."
oc delete deployment ollama -n agentic-ai-demo 2>/dev/null || echo "No existing deployment to clean"

echo "🔧 Creating service account with proper permissions..."

# Create a service account for Ollama
oc create serviceaccount ollama-sa -n agentic-ai-demo 2>/dev/null || echo "Service account already exists"

# Add the anyuid SCC to the service account (allows running as any user)
echo "🔐 Adding security context constraint..."
oc adm policy add-scc-to-user anyuid -z ollama-sa -n agentic-ai-demo

echo "📦 Creating OpenShift-compatible Ollama deployment..."

cat > ollama-openshift.yaml << 'EOF'
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
      serviceAccountName: ollama-sa  # Use the service account with anyuid SCC
      containers:
      - name: ollama
        image: ollama/ollama
        ports:
        - containerPort: 11434
        env:
        - name: OLLAMA_HOST
          value: "0.0.0.0"
        - name: OLLAMA_DATA_DIR
          value: "/tmp/ollama"
        - name: OLLAMA_MODELS
          value: "/tmp/ollama/models"
        - name: HOME
          value: "/tmp"
        # Memory-optimized settings
        - name: OLLAMA_NUM_PARALLEL
          value: "1"
        - name: OLLAMA_MAX_LOADED_MODELS
          value: "1"
        command: ["/bin/sh"]
        args:
        - -c
        - |
          echo "🚀 Starting Ollama with OpenShift compatibility..."
          
          # Create directories in /tmp (writable by any user)
          mkdir -p /tmp/ollama/models
          mkdir -p /tmp/ollama/.ollama
          
          # Set environment for Ollama
          export OLLAMA_HOME=/tmp/ollama/.ollama
          export OLLAMA_MODELS=/tmp/ollama/models
          
          echo "📁 Created directories in /tmp:"
          ls -la /tmp/ollama/
          
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
        - name: ollama-tmp
          mountPath: /tmp/ollama
        readinessProbe:
          httpGet:
            path: /api/tags
            port: 11434
          initialDelaySeconds: 60
          periodSeconds: 15
          timeoutSeconds: 10
          failureThreshold: 8
        livenessProbe:
          httpGet:
            path: /api/tags
            port: 11434
          initialDelaySeconds: 120
          periodSeconds: 30
          timeoutSeconds: 15
          failureThreshold: 5
      volumes:
      - name: ollama-tmp
        emptyDir:
          sizeLimit: 10Gi
EOF

echo "🚀 Deploying Ollama with OpenShift compatibility..."
oc apply -f ollama-openshift.yaml

# Clean up temp file
rm ollama-openshift.yaml

echo "⏳ Waiting for Ollama deployment..."
if oc rollout status deployment/ollama -n agentic-ai-demo --timeout=300s; then
    echo "✅ Ollama deployed successfully!"
    
    # Wait for readiness
    echo "⏳ Waiting for Ollama API to be ready..."
    for i in {1..15}; do
        if oc exec deployment/ollama -n agentic-ai-demo -- curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
            echo "✅ Ollama API is ready!"
            break
        else
            echo "   Waiting for API... ($i/15)"
            sleep 15
        fi
    done
    
    # Try to pull a model
    echo "🤖 Pulling lightweight model..."
    echo "   This will download tinyllama (~637MB) in the background"
    
    # Pull model in background
    oc exec deployment/ollama -n agentic-ai-demo -- ollama pull tinyllama &
    
    echo "✅ Model download started"
    echo ""
    echo "📊 Current status:"
    oc get pods -n agentic-ai-demo -l app=ollama
    
else
    echo "❌ Ollama deployment failed. Let's diagnose..."
    echo ""
    echo "🔍 Pod status:"
    oc get pods -n agentic-ai-demo -l app=ollama
    
    echo ""
    echo "🔍 Recent events:"
    oc get events -n agentic-ai-demo --field-selector involvedObject.name=ollama --sort-by='.lastTimestamp' | tail -5
    
    echo ""
    echo "🔍 Pod description:"
    POD_NAME=$(oc get pods -n agentic-ai-demo -l app=ollama -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$POD_NAME" ]; then
        oc describe pod $POD_NAME -n agentic-ai-demo | tail -20
    fi
fi

echo ""
echo "💡 Next steps:"
echo "   Check logs: oc logs -f deployment/ollama -n agentic-ai-demo"
echo "   Test API: oc exec deployment/ollama -n agentic-ai-demo -- curl http://localhost:11434/api/tags"
echo "   List models: oc exec deployment/ollama -n agentic-ai-demo -- ollama list"