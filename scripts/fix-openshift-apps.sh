#!/bin/bash

echo "🔧 Fixing OpenShift App Deployment Issues"
echo "========================================"

echo "🛑 Stopping problematic deployments..."
oc scale deployment support-api --replicas=0 -n agentic-ai-demo 2>/dev/null || echo "API not found"
oc scale deployment ai-support-app --replicas=0 -n agentic-ai-demo 2>/dev/null || echo "App not found"

echo "⏳ Waiting for pods to terminate..."
sleep 10

echo "🔧 Creating OpenShift-compatible app deployments..."

cat > openshift-apps.yaml << 'EOF'
# API Service - OpenShift Compatible
apiVersion: apps/v1
kind: Deployment
metadata:
  name: support-api
  namespace: agentic-ai-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: support-api
  template:
    metadata:
      labels:
        app: support-api
    spec:
      containers:
      - name: support-api
        image: python:3.12-slim
        ports:
        - containerPort: 8000
        env:
        - name: HOME
          value: "/tmp"
        - name: PYTHONUSERBASE
          value: "/tmp/.local"
        - name: PIP_USER
          value: "yes"
        - name: PIP_CACHE_DIR
          value: "/tmp/.cache"
        command: ["/bin/bash"]
        args:
        - -c
        - |
          echo "🚀 Starting API service with OpenShift compatibility..."
          
          # Set up writable directories
          mkdir -p /tmp/.local /tmp/.cache /tmp/app
          cd /tmp/app
          
          # Install Python packages to user directory
          echo "📦 Installing Python dependencies..."
          pip install --user --cache-dir=/tmp/.cache fastapi uvicorn pydantic requests
          
          # Create the API application
          echo "🤖 Creating AI Support API..."
          cat > main.py << 'PYEOF'
          from fastapi import FastAPI, HTTPException
          from pydantic import BaseModel
          import uuid
          import json
          import random
          from datetime import datetime, timedelta
          from typing import Dict, List
          
          app = FastAPI(title="AI Support API", description="OpenShift Compatible AI Support")
          
          # Customer database
          CUSTOMERS = {
              "CUST123": {
                  "account_id": "CUST123", 
                  "name": "Alice Smith", 
                  "service_status": "Active", 
                  "plan": "Premium Internet", 
                  "current_issues": [],
                  "device_id": "RTR-123"
              },
              "CUST456": {
                  "account_id": "CUST456", 
                  "name": "Bob Johnson", 
                  "service_status": "Issues Detected", 
                  "plan": "Basic Internet", 
                  "current_issues": ["internet_slow"],
                  "device_id": "RTR-456"
              },
              "CUST789": {
                  "account_id": "CUST789", 
                  "name": "Charlie Brown", 
                  "service_status": "Active", 
                  "plan": "TV + Internet", 
                  "current_issues": ["login_failure"],
                  "device_id": "STB-789"
              },
              "CUST000": {
                  "account_id": "CUST000", 
                  "name": "Demo Customer", 
                  "service_status": "Active", 
                  "plan": "Enterprise Fiber", 
                  "current_issues": [],
                  "device_id": "RTR-000"
              }
          }
          
          # Knowledge base
          KNOWLEDGE = {
              "internet slow": "Try restarting router, check bandwidth usage, run speed test",
              "login issue": "Verify credentials, clear cache, try incognito mode, reset password", 
              "connection down": "Check cables, restart modem/router, verify service status",
              "billing": "Review statement online, check payment method, contact billing"
          }
          
          # AI responses
          AI_TEMPLATES = {
              "connectivity": "I've analyzed your connectivity issue. Let me help you troubleshoot this systematically.",
              "account": "I'll help you resolve this account access issue quickly and securely.",
              "billing": "Let me review your billing details and help clarify any questions."
          }
          
          def analyze_issue(customer_id: str, query: str):
              query_lower = query.lower()
              customer = CUSTOMERS.get(customer_id, {})
              
              if any(word in query_lower for word in ["slow", "speed", "internet", "down"]):
                  category = "connectivity"
                  priority = "high" if "down" in query_lower else "medium"
              elif any(word in query_lower for word in ["login", "password", "access"]):
                  category = "account" 
                  priority = "medium"
              elif any(word in query_lower for word in ["billing", "payment", "charge"]):
                  category = "billing"
                  priority = "low"
              else:
                  category = "general"
                  priority = "medium"
              
              return {
                  "customer_priority": priority,
                  "issue_category": category,
                  "confidence": round(random.uniform(0.8, 0.95), 2),
                  "recommended_action": "troubleshoot",
                  "ai_response": AI_TEMPLATES.get(category, "I'll help you resolve this issue.")
              }
          
          @app.get("/")
          async def root():
              return {"service": "AI Support API", "status": "healthy", "version": "openshift-compatible"}
          
          @app.get("/health")
          async def health():
              return {"status": "healthy", "mode": "openshift-compatible"}
          
          @app.get("/account_status/{account_id}")
          async def get_account_status(account_id: str):
              customer = CUSTOMERS.get(account_id)
              if not customer:
                  raise HTTPException(status_code=404, detail="Customer not found")
              return customer
          
          @app.post("/knowledge_search")
          async def search_knowledge(query_data: dict):
              query = query_data.get("query", "").lower()
              results = []
              
              for keywords, content in KNOWLEDGE.items():
                  if any(word in query for word in keywords.split()):
                      results.append({
                          "title": f"Help with {keywords}",
                          "content": content,
                          "score": 0.85
                      })
              
              return {"results": results, "total": len(results)}
          
          @app.post("/ai_agent_analysis")
          async def ai_analysis(data: dict):
              customer_id = data.get("customer_id", "")
              query = data.get("query", "")
              
              analysis = analyze_issue(customer_id, query)
              
              return {
                  "agent_response": analysis,
                  "timestamp": datetime.now().isoformat(),
                  "agent_id": "openshift-ai-agent"
              }
          
          @app.get("/troubleshooting_steps/{issue_type}")
          async def get_troubleshooting_steps(issue_type: str):
              guides = {
                  "internet_slow": {
                      "issue": "Internet Speed Issues",
                      "steps": [
                          "1. Restart router (unplug 30 seconds)",
                          "2. Check bandwidth usage",
                          "3. Run speed test",
                          "4. Move closer to router",
                          "5. Contact support if issues persist"
                      ]
                  },
                  "login_issue": {
                      "issue": "Login Problems",
                      "steps": [
                          "1. Verify username/password",
                          "2. Clear browser cache",
                          "3. Try incognito mode",
                          "4. Reset password",
                          "5. Contact support for unlock"
                      ]
                  }
              }
              return guides.get(issue_type, {"error": "Guide not found"})
          
          @app.post("/create_ticket")
          async def create_ticket(ticket_data: dict):
              return {
                  "ticket_id": f"TICK-{str(uuid.uuid4())[:8].upper()}",
                  "customer_id": ticket_data.get("customer_id"),
                  "issue_summary": ticket_data.get("issue_summary"),
                  "priority": "medium",
                  "status": "Open",
                  "created_at": datetime.now().isoformat()
              }
          
          @app.post("/reboot_device/{device_id}")
          async def reboot_device(device_id: str):
              return {
                  "status": "success",
                  "message": f"Reboot initiated for {device_id}",
                  "timestamp": datetime.now().isoformat()
              }
          
          @app.get("/llm_status")
          async def llm_status():
              return {"status": "simulated", "mode": "rule-based"}
          PYEOF
          
          echo "🚀 Starting FastAPI server..."
          python -m uvicorn main:app --host 0.0.0.0 --port 8000
        workingDir: /tmp/app
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 30
---
apiVersion: v1
kind: Service
metadata:
  name: support-api
  namespace: agentic-ai-demo
spec:
  selector:
    app: support-api
  ports:
  - port: 8000
    targetPort: 8000
---
# Streamlit App - OpenShift Compatible
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
        - name: PIP_CACHE_DIR
          value: "/tmp/.cache"
        command: ["/bin/bash"]
        args:
        - -c
        - |
          echo "🚀 Starting Streamlit app with OpenShift compatibility..."
          
          # Set up writable directories
          mkdir -p /tmp/.local /tmp/.cache /tmp/app /tmp/.streamlit
          cd /tmp/app
          
          # Install dependencies
          echo "📦 Installing Streamlit and dependencies..."
          pip install --user --cache-dir=/tmp/.cache streamlit requests
          
          # Create Streamlit config
          cat > /tmp/.streamlit/config.toml << 'STEOF'
          [server]
          port = 8501
          address = "0.0.0.0"
          headless = true
          enableCORS = false
          enableXsrfProtection = false
          
          [browser]
          gatherUsageStats = false
          STEOF
          
          # Create the Streamlit app
          echo "🎨 Creating Streamlit application..."
          cat > app.py << 'PYEOF'
          import streamlit as st
          import requests
          import json
          import time
          
          st.set_page_config(page_title="🤖 AI Support", layout="wide")
          
          # Header
          st.markdown("""
          <div style="background: linear-gradient(90deg, #667eea 0%, #764ba2 100%); 
                      padding: 2rem; border-radius: 10px; color: white; text-align: center; margin-bottom: 2rem;">
              <h1>🤖 AI Support System</h1>
              <p>OpenShift Compatible Demo</p>
          </div>
          """, unsafe_allow_html=True)
          
          # Sidebar status
          with st.sidebar:
              st.markdown("### 🔧 System Status")
              
              try:
                  api_resp = requests.get("http://support-api:8000/health", timeout=3)
                  if api_resp.status_code == 200:
                      st.success("🟢 API Service")
                  else:
                      st.error("🔴 API Service")
              except:
                  st.warning("🟡 API Service")
              
              try:
                  weaviate_resp = requests.get("http://weaviate:8080/v1/meta", timeout=3)
                  if weaviate_resp.status_code == 200:
                      st.success("🟢 Vector DB")
                  else:
                      st.error("🔴 Vector DB")
              except:
                  st.warning("🟡 Vector DB")
              
              st.info("🤖 AI Simulation Active")
              
              st.markdown("---")
              st.markdown("### ✨ Features")
              st.markdown("✅ Customer Lookup")
              st.markdown("✅ Issue Analysis")
              st.markdown("✅ Knowledge Search")
              st.markdown("✅ Ticket Creation")
              st.markdown("✅ Device Management")
          
          # Main interface
          col1, col2 = st.columns([2, 1])
          
          with col1:
              st.markdown("### 🎯 Customer Support")
              
              inquiry = st.text_area(
                  "Describe your issue:",
                  height=120,
                  placeholder="e.g., I'm customer CUST123 and my internet is slow..."
              )
              
              if st.button("🔍 Analyze Issue", type="primary"):
                  if inquiry.strip():
                      analyze_issue(inquiry)
                  else:
                      st.warning("Please describe your issue.")
          
          with col2:
              st.markdown("### 🧪 Quick Tests")
              
              examples = [
                  "I'm customer CUST123 and my internet is slow",
                  "Customer CUST456 - login problems",
                  "CUST789 internet connection down", 
                  "CUST000 billing question"
              ]
              
              for i, example in enumerate(examples):
                  if st.button(f"📝 Test {i+1}", key=f"test_{i}"):
                      st.session_state.test_query = example
              
              if 'test_query' in st.session_state:
                  st.text_area("Selected:", value=st.session_state.test_query, height=60)
          
          def analyze_issue(inquiry):
              st.markdown("---")
              st.markdown("## 🤖 AI Analysis")
              
              import re
              cust_match = re.search(r'CUST\d+', inquiry.upper())
              
              if cust_match:
                  cust_id = cust_match.group()
                  
                  # Customer info
                  with st.expander("👤 Customer Information", expanded=True):
                      try:
                          response = requests.get(f"http://support-api:8000/account_status/{cust_id}", timeout=5)
                          if response.status_code == 200:
                              customer = response.json()
                              
                              col1, col2, col3 = st.columns(3)
                              with col1:
                                  st.metric("Customer", customer["name"])
                              with col2:
                                  st.metric("Plan", customer["plan"])
                              with col3:
                                  status = customer["service_status"]
                                  icon = "🟢" if status == "Active" else "🔴"
                                  st.metric("Status", f"{icon} {status}")
                              
                              if customer["current_issues"]:
                                  st.warning(f"⚠️ Active Issues: {', '.join(customer['current_issues'])}")
                          else:
                              st.error("Customer not found")
                      except Exception as e:
                          st.error(f"Error: {str(e)}")
                  
                  # AI Analysis
                  with st.expander("🧠 AI Analysis", expanded=True):
                      try:
                          ai_resp = requests.post(
                              "http://support-api:8000/ai_agent_analysis",
                              json={"customer_id": cust_id, "query": inquiry},
                              timeout=5
                          )
                          if ai_resp.status_code == 200:
                              ai_data = ai_resp.json()
                              analysis = ai_data["agent_response"]
                              
                              col1, col2 = st.columns(2)
                              with col1:
                                  st.metric("Priority", analysis["customer_priority"].upper())
                              with col2:
                                  st.metric("Category", analysis["issue_category"].title())
                              
                              st.success(f"✅ Confidence: {analysis['confidence']:.1%}")
                              st.info(analysis["ai_response"])
                          else:
                              st.error("AI analysis failed")
                      except Exception as e:
                          st.error(f"AI error: {str(e)}")
                  
                  # Knowledge search
                  with st.expander("🔍 Knowledge Base", expanded=True):
                      try:
                          kb_resp = requests.post(
                              "http://support-api:8000/knowledge_search",
                              json={"query": inquiry},
                              timeout=5
                          )
                          if kb_resp.status_code == 200:
                              kb_data = kb_resp.json()
                              if kb_data["results"]:
                                  for result in kb_data["results"]:
                                      st.info(f"💡 {result['content']}")
                              else:
                                  st.warning("No relevant knowledge found")
                          else:
                              st.error("Knowledge search failed")
                      except Exception as e:
                          st.error(f"Search error: {str(e)}")
                  
                  # Actions
                  with st.expander("🛠️ Actions", expanded=True):
                      col1, col2 = st.columns(2)
                      
                      with col1:
                          if st.button("📋 Create Ticket"):
                              try:
                                  ticket_resp = requests.post(
                                      "http://support-api:8000/create_ticket",
                                      json={"customer_id": cust_id, "issue_summary": inquiry[:50]},
                                      timeout=5
                                  )
                                  if ticket_resp.status_code == 200:
                                      ticket = ticket_resp.json()
                                      st.success(f"✅ Ticket: {ticket['ticket_id']}")
                                  else:
                                      st.error("Ticket creation failed")
                              except Exception as e:
                                  st.error(f"Error: {str(e)}")
                      
                      with col2:
                          device_id = customer.get("device_id", "UNKNOWN")
                          if st.button("🔄 Reboot Device"):
                              try:
                                  reboot_resp = requests.post(f"http://support-api:8000/reboot_device/{device_id}", timeout=5)
                                  if reboot_resp.status_code == 200:
                                      st.success("✅ Reboot initiated")
                                  else:
                                      st.error("Reboot failed")
                              except Exception as e:
                                  st.error(f"Error: {str(e)}")
              else:
                  st.warning("Please include a customer ID (e.g., CUST123) for analysis.")
          
          # Footer
          st.markdown("---")
          st.markdown("### 🚀 OpenShift Compatible Demo")
          st.markdown("This version runs with OpenShift security constraints and demonstrates core AI support functionality.")
          PYEOF
          
          echo "🎨 Starting Streamlit application..."
          export STREAMLIT_SERVER_HEADLESS=true
          python -m streamlit run app.py --server.port=8501 --server.address=0.0.0.0
        workingDir: /tmp/app
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
---
apiVersion: v1
kind: Service
metadata:
  name: ai-support-app
  namespace: agentic-ai-demo
spec:
  selector:
    app: ai-support-app
  ports:
  - port: 8501
    targetPort: 8501
---
# Routes
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ai-support-route
  namespace: agentic-ai-demo
spec:
  to:
    kind: Service
    name: ai-support-app
  port:
    targetPort: 8501
  tls:
    termination: edge
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: support-api-route
  namespace: agentic-ai-demo
spec:
  to:
    kind: Service
    name: support-api
  port:
    targetPort: 8000
  tls:
    termination: edge
EOF

echo "🚀 Deploying OpenShift-compatible applications..."
oc apply -f openshift-apps.yaml

# Clean up
rm openshift-apps.yaml

echo "⏳ Waiting for deployments..."
oc rollout status deployment/support-api -n agentic-ai-demo --timeout=300s
oc rollout status deployment/ai-support-app -n agentic-ai-demo --timeout=300s

echo ""
echo "📊 Deployment Status:"
oc get pods -n agentic-ai-demo

echo ""
echo "🌐 Application URLs:"
AI_ROUTE=$(oc get route ai-support-route -n agentic-ai-demo -o jsonpath='{.spec.host}' 2>/dev/null)
API_ROUTE=$(oc get route support-api-route -n agentic-ai-demo -o jsonpath='{.spec.host}' 2>/dev/null)

if [ -n "$AI_ROUTE" ]; then
    echo "   🤖 AI Support Demo: https://$AI_ROUTE"
else
    echo "   ⚠️  Demo route not ready yet"
fi

if [ -n "$API_ROUTE" ]; then
    echo "   🔧 API Documentation: https://$API_ROUTE/docs"
else
    echo "   ⚠️  API route not ready yet"
fi

echo ""
echo "✅ OpenShift-compatible deployment complete!"
echo ""
echo "💡 Key fixes applied:"
echo "   • Uses /tmp for writable directories"
echo "   • Installs Python packages to user directory"
echo "   • Sets proper environment variables"
echo "   • Compatible with OpenShift security constraints"
echo ""
echo "🔍 Monitor progress:"
echo "   oc logs -f deployment/support-api -n agentic-ai-demo"
echo "   oc logs -f deployment/ai-support-app -n agentic-ai-demo"