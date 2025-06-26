#!/bin/bash

echo "🔍 Diagnosing Streamlit CrashLoopBackOff"
echo "======================================="

# Get pod name
STREAMLIT_POD=$(oc get pods -n agentic-ai-demo -l app=ai-support-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$STREAMLIT_POD" ]; then
    echo "❌ No Streamlit pod found"
    exit 1
fi

echo "🔍 Pod: $STREAMLIT_POD"
echo ""

# Check pod status and events
echo "📊 Pod Status:"
oc get pod $STREAMLIT_POD -n agentic-ai-demo -o wide

echo ""
echo "📋 Pod Description (Events):"
oc describe pod $STREAMLIT_POD -n agentic-ai-demo | tail -20

echo ""
echo "📜 Recent Container Logs:"
oc logs $STREAMLIT_POD -n agentic-ai-demo --tail=50

echo ""
echo "📜 Previous Container Logs (if crashed):"
oc logs $STREAMLIT_POD -n agentic-ai-demo --previous --tail=30 2>/dev/null || echo "No previous logs available"

echo ""
echo "🔍 Container Status:"
oc get pod $STREAMLIT_POD -n agentic-ai-demo -o jsonpath='{.status.containerStatuses[0]}' | jq '.' 2>/dev/null || echo "Status not available"

echo ""
echo "=== ANALYSIS ==="

# Check for common issues
echo "🔍 Checking for common CrashLoop causes..."

# Check if it's a resource issue
RESTART_COUNT=$(oc get pod $STREAMLIT_POD -n agentic-ai-demo -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)
echo "🔄 Restart count: $RESTART_COUNT"

# Check resource requests vs limits
echo "💾 Resource configuration:"
oc get pod $STREAMLIT_POD -n agentic-ai-demo -o jsonpath='{.spec.containers[0].resources}' | jq '.' 2>/dev/null || echo "Resource info not available"

echo ""
echo "=== POTENTIAL FIXES ==="

echo "🛠️  Fix Option 1: Simplified Streamlit Deployment"
echo "   This creates a minimal Streamlit app that should work reliably"

echo ""
echo "🛠️  Fix Option 2: Debug Interactive Pod"
echo "   Create a debug pod to test commands manually"

echo ""
echo "🛠️  Fix Option 3: Use Pre-built Image"
echo "   Switch to a pre-built image with Streamlit already installed"

echo ""
read -p "Which fix would you like to try? (1/2/3): " -n 1 -r
echo

case $REPLY in
    1)
        echo "🔧 Applying simplified Streamlit deployment..."
        apply_simple_streamlit_fix
        ;;
    2)
        echo "🔧 Creating debug pod..."
        create_debug_pod
        ;;
    3)
        echo "🔧 Using pre-built image..."
        use_prebuilt_image
        ;;
    *)
        echo "❌ Invalid option. Please run the script again."
        ;;
esac

apply_simple_streamlit_fix() {
    echo "🛠️  Creating ultra-simple Streamlit deployment..."
    
    # Stop current deployment
    oc scale deployment ai-support-app --replicas=0 -n agentic-ai-demo
    sleep 10
    
    cat > simple-streamlit.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-support-app
  namespace: agentic-ai-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ai-support-app
  template:
    metadata:
      labels:
        app: ai-support-app
    spec:
      containers:
      - name: ai-support-app
        image: python:3.12-slim
        ports:
        - containerPort: 8501
        env:
        - name: HOME
          value: "/tmp"
        - name: PYTHONUSERBASE
          value: "/tmp/.local"
        - name: PIP_USER
          value: "yes"
        command: ["/bin/bash"]
        args:
        - -c
        - |
          set -e
          echo "🚀 Ultra-simple Streamlit startup..."
          
          # Create writable directories
          mkdir -p /tmp/.local/bin /tmp/app
          cd /tmp/app
          
          # Install minimal dependencies
          echo "📦 Installing minimal Streamlit..."
          pip install --user streamlit requests --no-cache-dir
          
          # Create the simplest possible Streamlit app
          echo "🎨 Creating minimal app..."
          cat > simple_app.py << 'PYEOF'
import streamlit as st
import requests

st.title("🤖 AI Support Demo")
st.write("OpenShift Compatible Version")

# Simple status check
st.subheader("System Status")

try:
    api_resp = requests.get("http://support-api:8000/health", timeout=3)
    if api_resp.status_code == 200:
        st.success("✅ API Service Connected")
    else:
        st.error("❌ API Service Error")
except:
    st.warning("⚠️ API Service Not Available")

# Simple form
st.subheader("Customer Support")
customer_id = st.text_input("Customer ID", placeholder="e.g. CUST123")
issue = st.text_area("Describe your issue", placeholder="My internet is slow...")

if st.button("Get Help"):
    if customer_id and issue:
        try:
            # Try to get customer info
            response = requests.get(f"http://support-api:8000/account_status/{customer_id}", timeout=5)
            if response.status_code == 200:
                customer = response.json()
                st.success(f"Found customer: {customer['name']}")
                st.json(customer)
            else:
                st.error("Customer not found")
        except Exception as e:
            st.error(f"Error: {str(e)}")
    else:
        st.warning("Please fill in both fields")

st.info("This is a simplified version of the AI support system running on OpenShift.")
PYEOF
          
          echo "🚀 Starting Streamlit with minimal config..."
          export PATH="/tmp/.local/bin:$PATH"
          streamlit run simple_app.py --server.port=8501 --server.address=0.0.0.0 --server.headless=true
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "400m"
        readinessProbe:
          httpGet:
            path: /
            port: 8501
          initialDelaySeconds: 45
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 8501
          initialDelaySeconds: 90
          periodSeconds: 30
EOF
    
    echo "🚀 Deploying simplified version..."
    oc apply -f simple-streamlit.yaml
    rm simple-streamlit.yaml
    
    echo "⏳ Waiting for deployment..."
    oc rollout status deployment/ai-support-app -n agentic-ai-demo --timeout=300s
    
    echo "✅ Simplified deployment complete!"
}

create_debug_pod() {
    echo "🔧 Creating debug pod for manual testing..."
    
    cat > debug-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: streamlit-debug
  namespace: agentic-ai-demo
spec:
  containers:
  - name: debug
    image: python:3.12-slim
    command: ["/bin/bash"]
    args: ["-c", "sleep 3600"]
    env:
    - name: HOME
      value: "/tmp"
    - name: PYTHONUSERBASE
      value: "/tmp/.local"
    - name: PIP_USER
      value: "yes"
EOF
    
    oc apply -f debug-pod.yaml
    rm debug-pod.yaml
    
    echo "✅ Debug pod created. To test manually:"
    echo "   oc exec -it streamlit-debug -n agentic-ai-demo -- /bin/bash"
    echo ""
    echo "   Then run these commands in the pod:"
    echo "   mkdir -p /tmp/.local /tmp/app && cd /tmp/app"
    echo "   pip install --user streamlit requests"
    echo "   # Create a simple app and test"
}

use_prebuilt_image() {
    echo "🔧 Using pre-built Streamlit image..."
    
    oc scale deployment ai-support-app --replicas=0 -n agentic-ai-demo
    sleep 10
    
    cat > prebuilt-streamlit.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-support-app
  namespace: agentic-ai-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ai-support-app
  template:
    metadata:
      labels:
        app: ai-support-app
    spec:
      containers:
      - name: ai-support-app
        image: streamlit/streamlit:latest
        ports:
        - containerPort: 8501
        command: ["/bin/bash"]
        args:
        - -c
        - |
          echo "🚀 Using pre-built Streamlit image..."
          
          cat > /app/simple_demo.py << 'EOF'
import streamlit as st
import requests

st.title("🤖 AI Support Demo (Pre-built)")
st.write("This version uses a pre-built Streamlit container")

if st.button("Test API"):
    try:
        resp = requests.get("http://support-api:8000/health", timeout=3)
        st.success("✅ API Connected")
        st.json(resp.json())
    except:
        st.error("❌ API Not Available")
EOF
          
          streamlit run /app/simple_demo.py --server.port=8501 --server.address=0.0.0.0
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "400m"
EOF
    
    oc apply -f prebuilt-streamlit.yaml
    rm prebuilt-streamlit.yaml
    
    echo "✅ Pre-built image deployment complete!"
}

echo ""
echo "📋 Next steps after applying fix:"
echo "   1. Monitor: oc logs -f deployment/ai-support-app -n agentic-ai-demo"
echo "   2. Check: oc get pods -n agentic-ai-demo"
echo "   3. Test: Access the route when ready"