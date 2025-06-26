#!/bin/bash

echo "🚀 Minimal CRC Deployment (No Weaviate - Resource Optimized)"
echo "=========================================================="

# Check if we're in the project root
if [ ! -f "docker-compose.yaml" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Check CRC resources
echo "💻 Checking CRC resources..."
CRC_MEMORY=$(crc config get memory 2>/dev/null || echo "unknown")
CRC_CPUS=$(crc config get cpus 2>/dev/null || echo "unknown")
echo "📊 CRC Resources: Memory=${CRC_MEMORY}MB, CPUs=${CRC_CPUS}"

if [ "$CRC_MEMORY" != "unknown" ] && [ "$CRC_MEMORY" -lt 6144 ]; then
    echo "⚠️  CRC memory is less than 6GB. For this minimal deployment:"
    echo "   Current: ${CRC_MEMORY}MB"
    echo "   Recommended: 6144MB+"
    echo ""
    echo "🔧 To increase CRC memory:"
    echo "   crc stop"
    echo "   crc config set memory 6144"
    echo "   crc start"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if CRC is running
if ! crc status | grep -q "Running"; then
    echo "⚠️  CRC is not running. Starting CRC..."
    crc start
fi

# Set up environment
eval $(crc oc-env)

# Get credentials
CRC_PASSWORD=$(crc console --credentials | grep "kubeadmin" | awk '{print $2}')

# Login
echo "🔐 Logging into OpenShift..."
oc login -u kubeadmin -p "$CRC_PASSWORD" https://api.crc.testing:6443 --insecure-skip-tls-verify=true

# Create project
echo "📦 Creating project..."
oc new-project agentic-ai-demo 2>/dev/null || oc project agentic-ai-demo

# Create a minimal deployment without Weaviate
echo "📝 Creating minimal deployment (no vector database)..."
cat > k8s/crc-minimal.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: agentic-ai-demo
---
# Lightweight API with in-memory knowledge base
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
        command: ["/bin/bash"]
        args:
        - -c
        - |
          pip install fastapi uvicorn pydantic
          cat > /app/main.py << 'PYEOF'
          from fastapi import FastAPI, HTTPException
          from pydantic import BaseModel
          import uuid
          from datetime import datetime, timedelta
          from typing import List, Dict, Any
          import json
          
          app = FastAPI(title="Minimal Support API", description="Resource-optimized support API for CRC")
          
          # Mock customer data
          MOCK_CUSTOMERS = {
              "CUST123": {
                  "account_id": "CUST123", 
                  "name": "Alice Smith", 
                  "service_status": "Active", 
                  "plan": "Premium Internet", 
                  "current_issues": [],
                  "last_login": "2024-01-15",
                  "data_usage": "85%"
              },
              "CUST456": {
                  "account_id": "CUST456", 
                  "name": "Bob Johnson", 
                  "service_status": "Issues Detected", 
                  "plan": "Basic Internet", 
                  "current_issues": ["internet_slow", "billing_issue"],
                  "last_login": "2024-01-10",
                  "data_usage": "45%"
              },
              "CUST789": {
                  "account_id": "CUST789", 
                  "name": "Charlie Brown", 
                  "service_status": "Active", 
                  "plan": "Standard TV + Internet", 
                  "current_issues": ["login_failure"],
                  "last_login": "Never",
                  "data_usage": "12%"
              },
              "CUST000": {
                  "account_id": "CUST000", 
                  "name": "Demo Customer", 
                  "service_status": "Active", 
                  "plan": "Fiber Max Enterprise", 
                  "current_issues": [],
                  "last_login": "2024-01-16",
                  "data_usage": "23%"
              }
          }
          
          # In-memory knowledge base (replaces Weaviate)
          KNOWLEDGE_BASE = {
              "internet_slow": {
                  "title": "Internet Speed Issues",
                  "content": "If your internet is slow, try these steps: 1) Restart your router by unplugging for 30 seconds, 2) Check for background downloads or streaming, 3) Run a speed test, 4) Move closer to your router, 5) Contact support if issues persist.",
                  "category": "connectivity",
                  "priority": "medium"
              },
              "internet_down": {
                  "title": "Internet Connection Down", 
                  "content": "For complete internet outages: 1) Check all cable connections, 2) Look for service outage notifications, 3) Power cycle your modem and router, 4) Check indicator lights, 5) Contact support for service restoration.",
                  "category": "connectivity",
                  "priority": "high"
              },
              "login_failure": {
                  "title": "Login Problems",
                  "content": "Cannot log into your account? 1) Verify username and password (case-sensitive), 2) Clear browser cache and cookies, 3) Try incognito/private browsing, 4) Use password reset if needed, 5) Wait 15 minutes if account is locked.",
                  "category": "account",
                  "priority": "medium"
              },
              "billing_issue": {
                  "title": "Billing Questions",
                  "content": "For billing concerns: 1) Review your latest statement online, 2) Check for recent service changes, 3) Verify payment method is current, 4) Contact billing department during business hours, 5) Request payment plan if needed.",
                  "category": "billing",
                  "priority": "low"
              },
              "tv_issues": {
                  "title": "TV Service Problems",
                  "content": "TV not working properly? 1) Check all connections to set-top box, 2) Restart the box by unplugging for 30 seconds, 3) Verify TV input setting, 4) Check for service interruptions, 5) Re-scan channels if needed.",
                  "category": "tv",
                  "priority": "medium"
              }
          }
          
          # Troubleshooting guides
          TROUBLESHOOTING_GUIDES = {
              "internet_slow": {
                  "issue": "Internet Speed Issues",
                  "steps": [
                      "1. Restart your router and modem (unplug for 30 seconds)",
                      "2. Check if multiple devices are using bandwidth heavily",
                      "3. Run a speed test at fast.com or speedtest.net",
                      "4. Move closer to your router if using Wi-Fi",
                      "5. Ensure router firmware is up to date",
                      "6. Try connecting directly with Ethernet cable",
                      "7. Contact support if speeds are significantly below your plan"
                  ],
                  "estimated_time": "15-20 minutes"
              },
              "no_internet_connection": {
                  "issue": "No Internet Connection",
                  "steps": [
                      "1. Check all cable connections (power, ethernet, coax)",
                      "2. Look for indicator lights on modem (should be solid blue/green)",
                      "3. Power cycle: unplug modem for 1 minute, then router",
                      "4. Wait 5 minutes for full reconnection",
                      "5. Check for service outages in your area",
                      "6. Try connecting different device to test",
                      "7. Contact support if no lights or continued issues"
                  ],
                  "estimated_time": "10-15 minutes"
              },
              "login_issue": {
                  "issue": "Account Login Problems",
                  "steps": [
                      "1. Double-check username and password (case-sensitive)",
                      "2. Ensure Caps Lock is off",
                      "3. Clear browser cache and cookies",
                      "4. Try different browser or incognito mode",
                      "5. Use 'Forgot Password' link to reset",
                      "6. Wait 15-30 minutes if account appears locked",
                      "7. Contact support for manual account unlock"
                  ],
                  "estimated_time": "5-10 minutes"
              }
          }
          
          # Pydantic models
          class TicketRequest(BaseModel):
              customer_id: str
              issue_summary: str
              priority: str = "Medium"
              
          class KnowledgeQuery(BaseModel):
              query: str
              
          # Health check
          @app.get("/health")
          async def health():
              return {"status": "healthy", "service": "minimal-support-api", "features": ["no-weaviate", "in-memory-kb"]}
          
          # Customer endpoints
          @app.get("/account_status/{account_id}")
          async def get_account_status(account_id: str):
              customer = MOCK_CUSTOMERS.get(account_id)
              if not customer:
                  raise HTTPException(status_code=404, detail="Account not found")
              return customer
          
          # Knowledge base search (simple keyword matching instead of vector search)
          @app.post("/knowledge_search")
          async def search_knowledge(query: KnowledgeQuery):
              results = []
              query_lower = query.query.lower()
              
              for key, article in KNOWLEDGE_BASE.items():
                  # Simple keyword matching
                  if (query_lower in article["content"].lower() or 
                      query_lower in article["title"].lower() or
                      any(word in article["content"].lower() for word in query_lower.split())):
                      results.append({
                          "id": key,
                          "title": article["title"],
                          "content": article["content"],
                          "category": article["category"],
                          "relevance_score": 0.8  # Mock score
                      })
              
              return {"results": results, "total": len(results)}
          
          # Troubleshooting endpoints
          @app.get("/troubleshooting_steps/{issue_type}")
          async def get_troubleshooting_steps(issue_type: str):
              guide = TROUBLESHOOTING_GUIDES.get(issue_type)
              if not guide:
                  raise HTTPException(status_code=404, detail=f"No troubleshooting guide found for '{issue_type}'")
              return guide
          
          # Ticketing
          @app.post("/create_ticket")
          async def create_ticket(ticket_request: TicketRequest):
              ticket_id = f"TICK-{str(uuid.uuid4())[:8].upper()}"
              created_at = datetime.now()
              
              # Set estimated resolution based on priority
              if ticket_request.priority.lower() == "high":
                  est_resolution = created_at + timedelta(hours=4)
              elif ticket_request.priority.lower() == "medium":
                  est_resolution = created_at + timedelta(hours=24)
              else:
                  est_resolution = created_at + timedelta(days=3)
              
              ticket = {
                  "ticket_id": ticket_id,
                  "customer_id": ticket_request.customer_id,
                  "issue_summary": ticket_request.issue_summary,
                  "priority": ticket_request.priority,
                  "status": "Open",
                  "created_at": created_at.isoformat(),
                  "estimated_resolution": est_resolution.isoformat(),
                  "assigned_agent": "AI Support Bot"
              }
              
              return ticket
          
          # Device management
          @app.post("/reboot_device/{device_id}")
          async def reboot_device(device_id: str):
              return {
                  "status": "success",
                  "message": f"Remote reboot command sent to device {device_id}",
                  "device_id": device_id,
                  "timestamp": datetime.now().isoformat()
              }
          
          # List all available endpoints for demo purposes
          @app.get("/")
          async def root():
              return {
                  "service": "Minimal AI Support API",
                  "version": "1.0.0",
                  "features": ["Customer Management", "Knowledge Base", "Troubleshooting", "Ticketing", "Device Control"],
                  "endpoints": {
                      "health": "/health",
                      "customer": "/account_status/{customer_id}",
                      "knowledge": "/knowledge_search",
                      "troubleshooting": "/troubleshooting_steps/{issue_type}",
                      "tickets": "/create_ticket",
                      "device": "/reboot_device/{device_id}",
                      "docs": "/docs"
                  }
              }
          PYEOF
          cd /app && python -m uvicorn main:app --host 0.0.0.0 --port 8000
        workingDir: /app
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
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
# Minimal Streamlit app
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
        command: ["/bin/bash"]
        args:
        - -c
        - |
          pip install streamlit requests
          cat > /app/demo_app.py << 'PYEOF'
          import streamlit as st
          import requests
          import json
          
          st.set_page_config(page_title="AI Support Demo", page_icon="🤖", layout="wide")
          
          # Custom CSS
          st.markdown("""
          <style>
          .main-header {
              font-size: 2.5rem;
              color: #1f77b4;
              text-align: center;
              margin-bottom: 2rem;
          }
          .demo-badge {
              background-color: #ff6b6b;
              color: white;
              padding: 0.5rem 1rem;
              border-radius: 20px;
              font-size: 0.8rem;
              margin-bottom: 1rem;
          }
          </style>
          """, unsafe_allow_html=True)
          
          st.markdown('<div class="main-header">🤖 AI Support Assistant</div>', unsafe_allow_html=True)
          st.markdown('<div class="demo-badge">🚀 CRC Demo - Minimal Resource Version</div>', unsafe_allow_html=True)
          
          col1, col2 = st.columns([2, 1])
          
          with col1:
              st.markdown("### 📝 Describe your issue:")
              inquiry = st.text_area("", height=150, placeholder="e.g., I'm customer CUST123 and my internet is slow...")
              
              if st.button("🔍 Get AI Support", type="primary"):
                  if inquiry.strip():
                      with st.spinner("🤖 AI agents are analyzing your issue..."):
                          st.markdown("---")
                          
                          # Extract customer ID
                          import re
                          cust_match = re.search(r'CUST\d+', inquiry.upper())
                          
                          if cust_match:
                              cust_id = cust_match.group()
                              st.markdown(f"### 👤 Customer Information for {cust_id}")
                              
                              try:
                                  response = requests.get(f"http://support-api:8000/account_status/{cust_id}", timeout=5)
                                  if response.status_code == 200:
                                      customer_data = response.json()
                                      
                                      col_a, col_b, col_c = st.columns(3)
                                      with col_a:
                                          st.metric("Customer", customer_data["name"])
                                          st.metric("Plan", customer_data["plan"])
                                      with col_b:
                                          status_color = "🟢" if customer_data["service_status"] == "Active" else "🔴"
                                          st.metric("Status", f'{status_color} {customer_data["service_status"]}')
                                          st.metric("Data Usage", customer_data.get("data_usage", "N/A"))
                                      with col_c:
                                          st.metric("Last Login", customer_data.get("last_login", "Unknown"))
                                          st.metric("Open Issues", len(customer_data["current_issues"]))
                                      
                                      if customer_data["current_issues"]:
                                          st.warning(f"⚠️ Known issues: {', '.join(customer_data['current_issues'])}")
                                  else:
                                      st.error(f"❌ Customer {cust_id} not found")
                              except Exception as e:
                                  st.error(f"❌ Could not retrieve customer data: {str(e)}")
                          
                          # Knowledge base search
                          st.markdown("### 🧠 AI Knowledge Search")
                          try:
                              kb_response = requests.post(
                                  "http://support-api:8000/knowledge_search",
                                  json={"query": inquiry},
                                  timeout=5
                              )
                              if kb_response.status_code == 200:
                                  kb_data = kb_response.json()
                                  if kb_data["results"]:
                                      for result in kb_data["results"][:2]:  # Show top 2 results
                                          with st.expander(f"📚 {result['title']} (Category: {result['category']})"):
                                              st.write(result["content"])
                                  else:
                                      st.info("🔍 No specific knowledge articles found for your query.")
                              else:
                                  st.error("❌ Knowledge search failed")
                          except Exception as e:
                              st.error(f"❌ Knowledge search error: {str(e)}")
                          
                          # Troubleshooting suggestions
                          st.markdown("### 🛠️ Troubleshooting Suggestions")
                          issue_keywords = {
                              "slow": "internet_slow",
                              "down": "no_internet_connection", 
                              "login": "login_issue",
                              "internet": "internet_slow",
                              "connection": "no_internet_connection"
                          }
                          
                          suggested_guide = None
                          for keyword, guide_key in issue_keywords.items():
                              if keyword in inquiry.lower():
                                  suggested_guide = guide_key
                                  break
                          
                          if suggested_guide:
                              try:
                                  ts_response = requests.get(f"http://support-api:8000/troubleshooting_steps/{suggested_guide}", timeout=5)
                                  if ts_response.status_code == 200:
                                      guide_data = ts_response.json()
                                      st.success(f"✅ {guide_data['issue']} (Est. time: {guide_data.get('estimated_time', 'N/A')})")
                                      for step in guide_data["steps"]:
                                          st.write(f"• {step}")
                                  else:
                                      st.warning("⚠️ No specific troubleshooting guide available")
                              except Exception as e:
                                  st.error(f"❌ Troubleshooting guide error: {str(e)}")
                          else:
                              st.info("💡 For specific troubleshooting steps, mention keywords like 'slow', 'down', or 'login' in your query.")
                          
                          # Offer to create ticket
                          if cust_match:
                              st.markdown("### 🎫 Support Ticket")
                              if st.button("📋 Create Support Ticket"):
                                  try:
                                      ticket_response = requests.post(
                                          "http://support-api:8000/create_ticket",
                                          json={
                                              "customer_id": cust_id,
                                              "issue_summary": inquiry[:100] + "..." if len(inquiry) > 100 else inquiry,
                                              "priority": "Medium"
                                          },
                                          timeout=5
                                      )
                                      if ticket_response.status_code == 200:
                                          ticket_data = ticket_response.json()
                                          st.success(f"✅ Ticket created: {ticket_data['ticket_id']}")
                                          st.info(f"📅 Estimated resolution: {ticket_data['estimated_resolution'][:10]}")
                                      else:
                                          st.error("❌ Failed to create ticket")
                                  except Exception as e:
                                      st.error(f"❌ Ticket creation error: {str(e)}")
                  else:
                      st.warning("⚠️ Please describe your issue to get help.")
          
          with col2:
              st.markdown("### 🧪 Demo Guide")
              st.markdown("**Try these examples:**")
              
              examples = [
                  "I'm customer CUST123 and my internet is slow",
                  "Customer CUST456 login problems", 
                  "CUST789 internet connection down",
                  "CUST000 billing question"
              ]
              
              for example in examples:
                  if st.button(f"📋 {example}", key=example):
                      st.session_state.example_query = example
              
              if 'example_query' in st.session_state:
                  st.text_area("Selected example:", value=st.session_state.example_query, height=100)
              
              st.markdown("---")
              st.markdown("### ℹ️ Demo Features")
              st.markdown("✅ Customer lookup")
              st.markdown("✅ Knowledge base search")  
              st.markdown("✅ Troubleshooting guides")
              st.markdown("✅ Ticket creation")
              st.markdown("✅ Minimal resource usage")
              st.markdown("❌ Vector database (removed)")
              st.markdown("❌ LLM models (simplified)")
              
              st.markdown("---")
              st.markdown("### 🚀 Full Version")
              st.markdown("The complete demo includes:")
              st.markdown("• CrewAI multi-agent system")
              st.markdown("• Weaviate vector database")
              st.markdown("• Ollama/Llamastack integration")
              st.markdown("• Advanced AI reasoning")
          PYEOF
          cd /app && streamlit run demo_app.py --server.port=8501 --server.address=0.0.0.0
        workingDir: /app
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "400m"
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
    insecureEdgeTerminationPolicy: Redirect
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
    insecureEdgeTerminationPolicy: Redirect
EOF

# Deploy the minimal version
echo "🚀 Deploying minimal version (no Weaviate)..."
oc apply -f k8s/crc-minimal.yaml

# Wait for deployments with shorter timeout
echo "⏳ Waiting for deployments..."
oc rollout status deployment/support-api -n agentic-ai-demo --timeout=180s
oc rollout status deployment/ai-support-app -n agentic-ai-demo --timeout=180s

# Check deployment status
echo ""
echo "📊 Deployment Status:"
oc get pods -n agentic-ai-demo

# Get routes
echo ""
echo "✅ Minimal deployment complete!"
echo ""
echo "🌐 Application URLs:"
AI_ROUTE=$(oc get route ai-support-route -n agentic-ai-demo -o jsonpath='{.spec.host}' 2>/dev/null)
API_ROUTE=$(oc get route support-api-route -n agentic-ai-demo -o jsonpath='{.spec.host}' 2>/dev/null)

if [ -n "$AI_ROUTE" ]; then
    echo "   🤖 AI Support Demo: https://$AI_ROUTE"
else
    echo "   ⚠️  AI Support Demo route not found"
fi

if [ -n "$API_ROUTE" ]; then
    echo "   🔧 API Documentation: https://$API_ROUTE/docs"
else
    echo "   ⚠️  API route not found"
fi

echo ""
echo "💾 Resource Usage:"
echo "   • No Weaviate vector database"
echo "   • Lightweight in-memory knowledge base"
echo "   • Minimal CPU/memory requirements"
echo "   • Simple keyword-based search"
echo ""
echo "📊 OpenShift Console: https://console-openshift-console.apps-crc.testing"
echo "👤 Login: kubeadmin / $CRC_PASSWORD"
echo ""
echo "🔍 Useful commands:"
echo "   oc get pods -n agentic-ai-demo"
echo "   oc logs -f deployment/ai-support-app -n agentic-ai-demo"
echo "   oc logs -f deployment/support-api -n agentic-ai-demo"
echo ""
echo "🛑 To clean up: oc delete project agentic-ai-demo"