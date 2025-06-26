#!/bin/bash

echo "🔧 Deploying Simple Working App (No Syntax Issues)"
echo "================================================="

echo "🛑 Stopping current deployment..."
oc scale deployment ai-support-app --replicas=0 -n agentic-ai-demo

echo "⏳ Waiting for pod to stop..."
sleep 10

echo "🔧 Creating bulletproof deployment..."

cat > simple-working.yaml << 'EOF'
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
          echo "🚀 Simple working deployment..."
          
          # Create directories
          mkdir -p /tmp/.local/bin /tmp/app
          cd /tmp/app
          
          # Install packages
          echo "📦 Installing Streamlit..."
          pip install --user streamlit requests --no-cache-dir
          
          # Create Python file using Python itself to avoid shell escaping issues
          echo "🎨 Creating app with Python..."
          python3 << 'PYTHONEOF'
app_content = '''import streamlit as st
import requests
import json

st.title("🤖 AI Support Demo")
st.write("Successfully running on OpenShift!")

# System status
st.header("System Status")

try:
    resp = requests.get("http://support-api:8000/health", timeout=3)
    if resp.status_code == 200:
        st.success("✅ API Service Connected")
        st.json(resp.json())
    else:
        st.error("❌ API Service Error")
except:
    st.warning("⚠️ API Service Starting...")

# Customer support
st.header("Customer Support")

customer_id = st.text_input("Customer ID", placeholder="CUST123")
issue = st.text_area("Issue Description", placeholder="My internet is slow...")

if st.button("Get Support"):
    if customer_id and issue:
        try:
            # Get customer info
            resp = requests.get("http://support-api:8000/account_status/" + customer_id, timeout=5)
            if resp.status_code == 200:
                customer = resp.json()
                st.success("✅ Customer Found: " + customer.get("name", "Unknown"))
                
                # Show customer details
                col1, col2 = st.columns(2)
                with col1:
                    st.metric("Name", customer.get("name", "N/A"))
                    st.metric("Plan", customer.get("plan", "N/A"))
                with col2:
                    st.metric("Status", customer.get("service_status", "N/A"))
                    st.metric("Device", customer.get("device_id", "N/A"))
                
                # Show full details
                st.json(customer)
                
                # AI Analysis
                try:
                    ai_resp = requests.post(
                        "http://support-api:8000/ai_agent_analysis",
                        json={"customer_id": customer_id, "query": issue},
                        timeout=5
                    )
                    if ai_resp.status_code == 200:
                        ai_data = ai_resp.json()
                        analysis = ai_data["agent_response"]
                        st.success("🤖 AI Analysis Complete")
                        st.write("Priority:", analysis.get("customer_priority", "N/A"))
                        st.write("Category:", analysis.get("issue_category", "N/A"))
                        st.info(analysis.get("ai_response", "No response"))
                except:
                    st.info("🤖 AI analysis not available")
                
                # Action buttons
                col_a, col_b = st.columns(2)
                with col_a:
                    if st.button("Create Ticket"):
                        try:
                            ticket_resp = requests.post(
                                "http://support-api:8000/create_ticket",
                                json={"customer_id": customer_id, "issue_summary": issue},
                                timeout=5
                            )
                            if ticket_resp.status_code == 200:
                                ticket = ticket_resp.json()
                                st.success("Ticket created: " + ticket.get("ticket_id", "Unknown"))
                        except:
                            st.error("Ticket creation failed")
                
                with col_b:
                    if st.button("Reboot Device"):
                        device_id = customer.get("device_id", "UNKNOWN")
                        try:
                            reboot_resp = requests.post("http://support-api:8000/reboot_device/" + device_id, timeout=5)
                            if reboot_resp.status_code == 200:
                                st.success("Device reboot initiated")
                        except:
                            st.error("Reboot failed")
            else:
                st.error("❌ Customer not found")
        except Exception as e:
            st.error("Error: " + str(e))
    else:
        st.warning("Please fill in both fields")

# Test cases
st.header("Quick Test Cases")
test_cases = [
    ("CUST123", "Internet speed issues"),
    ("CUST456", "Login problems"), 
    ("CUST789", "Connection down"),
    ("CUST000", "Billing question")
]

for i, (cid, desc) in enumerate(test_cases):
    if st.button(f"Test {i+1}: {cid}", key=f"test_{i}"):
        st.write(f"Customer: {cid}")
        st.write(f"Issue: {desc}")

st.success("🎯 Full AI Support Demo Running Successfully!")
'''

with open('/tmp/app/app.py', 'w') as f:
    f.write(app_content)

print("✅ App file created successfully")
PYTHONEOF
          
          # Verify file creation
          echo "📋 Verifying app file..."
          ls -la app.py
          echo "File size: $(wc -l < app.py) lines"
          
          # Test Python syntax
          echo "🔍 Testing Python syntax..."
          python3 -m py_compile app.py
          echo "✅ Syntax check passed"
          
          # Start streamlit
          echo "🚀 Starting Streamlit..."
          streamlit run app.py --server.port=8501 --server.address=0.0.0.0 --server.headless=true
        resources:
          requests:
            memory: "512Mi"
            cpu: "300m"
          limits:
            memory: "1Gi"
            cpu: "600m"
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

echo "🚀 Applying bulletproof deployment..."
oc apply -f simple-working.yaml

# Clean up
rm simple-working.yaml

echo "⏳ Waiting for deployment..."
oc rollout status deployment/ai-support-app -n agentic-ai-demo --timeout=300s

echo ""
echo "📊 Deployment status:"
oc get pods -n agentic-ai-demo -l app=ai-support-app

echo ""
echo "🌐 Demo URL:"
APP_ROUTE=$(oc get route ai-support-route -n agentic-ai-demo -o jsonpath='{.spec.host}' 2>/dev/null)
if [ -n "$APP_ROUTE" ]; then
    echo "   https://$APP_ROUTE"
else
    echo "   Route not ready yet"
fi

echo ""
echo "🔍 Monitor:"
echo "   oc logs -f deployment/ai-support-app -n agentic-ai-demo"

echo ""
echo "✅ This approach uses Python to create the file, avoiding all shell escaping issues!"