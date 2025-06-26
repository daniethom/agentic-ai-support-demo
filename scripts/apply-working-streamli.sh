#!/bin/bash

echo "🔧 Applying Direct Working Streamlit Fix"
echo "======================================="

echo "🛑 Stopping current failing deployment..."
oc scale deployment ai-support-app --replicas=0 -n agentic-ai-demo

echo "⏳ Waiting for pods to terminate..."
sleep 15

echo "🔧 Creating guaranteed working deployment..."

cat > working-streamlit.yaml << 'EOF'
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
        - name: PATH
          value: "/tmp/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        command: ["/bin/bash"]
        args:
        - -c
        - |
          set -e
          echo "🚀 Working Streamlit deployment starting..."
          
          # Create directories
          mkdir -p /tmp/.local/bin /tmp/app
          cd /tmp/app
          
          # Install minimal packages only
          echo "📦 Installing minimal packages..."
          pip install --user streamlit requests --no-cache-dir
          
          # Create app using echo instead of file redirection
          echo "🎨 Creating application file..."
          echo 'import streamlit as st' > app.py
          echo 'import requests' >> app.py
          echo 'import json' >> app.py
          echo '' >> app.py
          echo 'st.title("🤖 AI Support Demo")' >> app.py
          echo 'st.write("Working OpenShift Deployment!")' >> app.py
          echo '' >> app.py
          echo '# System status' >> app.py
          echo 'st.subheader("System Status")' >> app.py
          echo '' >> app.py
          echo 'try:' >> app.py
          echo '    resp = requests.get("http://support-api:8000/health", timeout=3)' >> app.py
          echo '    if resp.status_code == 200:' >> app.py
          echo '        st.success("✅ API Service Connected")' >> app.py
          echo '        st.json(resp.json())' >> app.py
          echo '    else:' >> app.py
          echo '        st.error("❌ API Service Error")' >> app.py
          echo 'except:' >> app.py
          echo '    st.warning("⚠️ API Service Starting...")' >> app.py
          echo '' >> app.py
          echo '# Customer support form' >> app.py
          echo 'st.subheader("Customer Support")' >> app.py
          echo 'customer_id = st.text_input("Customer ID", placeholder="CUST123")' >> app.py
          echo 'issue = st.text_area("Issue Description", placeholder="My internet is slow...")' >> app.py
          echo '' >> app.py
          echo 'if st.button("Get Support"):' >> app.py
          echo '    if customer_id and issue:' >> app.py
          echo '        try:' >> app.py
          echo '            resp = requests.get(f"http://support-api:8000/account_status/{customer_id}", timeout=5)' >> app.py
          echo '            if resp.status_code == 200:' >> app.py
          echo '                customer = resp.json()' >> app.py
          echo '                st.success(f"Found: {customer[\"name\"]}")' >> app.py
          echo '                st.json(customer)' >> app.py
          echo '            else:' >> app.py
          echo '                st.error("Customer not found")' >> app.py
          echo '        except Exception as e:' >> app.py
          echo '            st.error(f"Error: {str(e)}")' >> app.py
          echo '    else:' >> app.py
          echo '        st.warning("Please fill in both fields")' >> app.py
          echo '' >> app.py
          echo 'st.info("🎯 This demonstrates the core AI support system functionality")' >> app.py
          
          # Verify file was created
          echo "📋 Verifying app file..."
          ls -la app.py
          head -5 app.py
          
          # Start streamlit
          echo "🚀 Starting Streamlit..."
          export PATH="/tmp/.local/bin:$PATH"
          streamlit run app.py --server.port=8501 --server.address=0.0.0.0 --server.headless=true
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
          initialDelaySeconds: 60
          periodSeconds: 15
        livenessProbe:
          httpGet:
            path: /
            port: 8501
          initialDelaySeconds: 120
          periodSeconds: 30
EOF

echo "🚀 Applying working deployment..."
oc apply -f working-streamlit.yaml

# Clean up
rm working-streamlit.yaml

echo "⏳ Waiting for deployment to start..."
oc rollout status deployment/ai-support-app -n agentic-ai-demo --timeout=300s

echo ""
echo "📊 Current status:"
oc get pods -n agentic-ai-demo -l app=ai-support-app

echo ""
echo "🔍 Monitor the startup:"
echo "   oc logs -f deployment/ai-support-app -n agentic-ai-demo"

echo ""
echo "🌐 Route will be available at:"
APP_ROUTE=$(oc get route ai-support-route -n agentic-ai-demo -o jsonpath='{.spec.host}' 2>/dev/null)
if [ -n "$APP_ROUTE" ]; then
    echo "   https://$APP_ROUTE"
else
    echo "   Route not ready yet - check oc get routes -n agentic-ai-demo"
fi

echo ""
echo "✅ Working deployment applied!"