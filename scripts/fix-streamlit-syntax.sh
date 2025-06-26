#!/bin/bash

echo "🔧 Fixing Streamlit Syntax Error"
echo "==============================="

echo "🛑 Stopping current deployment..."
oc scale deployment ai-support-app --replicas=0 -n agentic-ai-demo

echo "⏳ Waiting for pod to stop..."
sleep 10

echo "🔧 Creating deployment with fixed syntax..."

cat > fixed-streamlit.yaml << 'EOF'
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
          echo "🚀 Fixed Streamlit deployment starting..."
          
          # Create directories
          mkdir -p /tmp/.local/bin /tmp/app
          cd /tmp/app
          
          # Install packages
          echo "📦 Installing Streamlit..."
          pip install --user streamlit requests --no-cache-dir
          
          # Create app with proper syntax
          echo "🎨 Creating application with fixed syntax..."
          cat > app.py << 'PYEOF'
import streamlit as st
import requests
import json

st.set_page_config(page_title="AI Support Demo", layout="wide")

# Header
st.markdown("""
<div style="background: linear-gradient(90deg, #667eea 0%, #764ba2 100%); 
            padding: 2rem; border-radius: 10px; color: white; text-align: center; margin-bottom: 2rem;">
    <h1>🤖 AI Support System</h1>
    <p>OpenShift Demo - Now Working!</p>
</div>
""", unsafe_allow_html=True)

# System status check
st.subheader("🔧 System Status")

col1, col2, col3 = st.columns(3)

with col1:
    try:
        api_resp = requests.get("http://support-api:8000/health", timeout=3)
        if api_resp.status_code == 200:
            st.success("✅ API Service")
            health_data = api_resp.json()
            st.caption(f"Mode: {health_data.get('mode', 'unknown')}")
        else:
            st.error("🔴 API Service")
    except:
        st.warning("🟡 API Starting...")

with col2:
    try:
        weaviate_resp = requests.get("http://weaviate:8080/v1/meta", timeout=3)
        if weaviate_resp.status_code == 200:
            st.success("✅ Vector DB")
        else:
            st.error("🔴 Vector DB")
    except:
        st.warning("🟡 Vector DB")

with col3:
    try:
        ollama_resp = requests.get("http://ollama:11434/api/tags", timeout=3)
        if ollama_resp.status_code == 200:
            st.success("✅ LLM Service")
            models = ollama_resp.json().get("models", [])
            st.caption(f"Models: {len(models)}")
        else:
            st.info("🔵 LLM Loading")
    except:
        st.info("🔵 LLM Starting")

st.markdown("---")

# Main interface
col1, col2 = st.columns([2, 1])

with col1:
    st.subheader("🎯 Customer Support Assistant")
    
    customer_id = st.text_input("Customer ID", placeholder="e.g., CUST123")
    issue = st.text_area("Issue Description", height=100, 
                        placeholder="Describe your technical issue...")
    
    if st.button("🔍 Analyze Issue", type="primary"):
        if customer_id and issue:
            with st.spinner("Analyzing..."):
                # Customer lookup
                try:
                    resp = requests.get(f"http://support-api:8000/account_status/{customer_id}", timeout=5)
                    if resp.status_code == 200:
                        customer = resp.json()
                        st.success("✅ Customer Found")
                        
                        # Display customer info
                        col_a, col_b, col_c = st.columns(3)
                        with col_a:
                            st.metric("Customer", customer["name"])
                        with col_b:
                            st.metric("Plan", customer["plan"])
                        with col_c:
                            status = customer["service_status"]
                            icon = "🟢" if status == "Active" else "🔴"
                            st.metric("Status", f"{icon} {status}")
                        
                        # Show any current issues
                        if customer.get("current_issues"):
                            st.warning(f"⚠️ Active Issues: {', '.join(customer['current_issues'])}")
                        
                        st.json(customer)
                    else:
                        st.error("❌ Customer not found")
                except Exception as e:
                    st.error(f"❌ Error: {str(e)}")
                
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
                        col_x, col_y = st.columns(2)
                        with col_x:
                            st.metric("Priority", analysis["customer_priority"].upper())
                        with col_y:
                            st.metric("Category", analysis["issue_category"].title())
                        
                        st.info(f"💬 AI: {analysis['ai_response']}")
                    else:
                        st.warning("⚠️ AI analysis not available")
                except Exception as e:
                    st.warning(f"⚠️ AI analysis error: {str(e)}")
                
                # Knowledge search
                try:
                    kb_resp = requests.post(
                        "http://support-api:8000/knowledge_search",
                        json={"query": issue},
                        timeout=5
                    )
                    if kb_resp.status_code == 200:
                        kb_data = kb_resp.json()
                        if kb_data["results"]:
                            st.success("📚 Knowledge Base Results")
                            for result in kb_data["results"][:2]:
                                with st.expander(f"💡 {result.get('title', 'Solution')}"):
                                    st.write(result.get("content", "No content"))
                        else:
                            st.info("🔍 No specific knowledge articles found")
                    else:
                        st.warning("⚠️ Knowledge search not available")
                except Exception as e:
                    st.warning(f"⚠️ Knowledge search error: {str(e)}")
                
                # Action buttons
                st.markdown("### 🛠️ Actions")
                col_action1, col_action2 = st.columns(2)
                
                with col_action1:
                    if st.button("📋 Create Ticket"):
                        try:
                            ticket_resp = requests.post(
                                "http://support-api:8000/create_ticket",
                                json={"customer_id": customer_id, "issue_summary": issue[:100]},
                                timeout=5
                            )
                            if ticket_resp.status_code == 200:
                                ticket = ticket_resp.json()
                                st.success(f"✅ Ticket Created: {ticket['ticket_id']}")
                            else:
                                st.error("❌ Ticket creation failed")
                        except Exception as e:
                            st.error(f"❌ Error: {str(e)}")
                
                with col_action2:
                    if st.button("🔄 Device Reboot"):
                        device_id = customer.get("device_id", "UNKNOWN") if 'customer' in locals() else "UNKNOWN"
                        try:
                            reboot_resp = requests.post(f"http://support-api:8000/reboot_device/{device_id}", timeout=5)
                            if reboot_resp.status_code == 200:
                                st.success("✅ Device reboot initiated")
                            else:
                                st.error("❌ Reboot failed")
                        except Exception as e:
                            st.error(f"❌ Error: {str(e)}")
        else:
            st.warning("⚠️ Please fill in both Customer ID and Issue Description")

with col2:
    st.subheader("🧪 Quick Test Cases")
    
    test_cases = [
        ("🐌 Speed Issue", "CUST123", "My internet is very slow today"),
        ("🔐 Login Problem", "CUST456", "Cannot access my account"),
        ("📡 Outage", "CUST789", "Internet connection is down"),
        ("💳 Billing", "CUST000", "Question about my bill")
    ]
    
    for i, (title, cid, desc) in enumerate(test_cases):
        if st.button(title, key=f"test_{i}"):
            st.session_state.test_customer = cid
            st.session_state.test_issue = desc
    
    if 'test_customer' in st.session_state:
        st.text_input("Test Customer ID:", value=st.session_state.test_customer, key="test_cid")
        st.text_area("Test Issue:", value=st.session_state.test_issue, height=80, key="test_desc")

# Footer
st.markdown("---")
st.markdown("### ✅ Demo Successfully Running on OpenShift!")

col_f1, col_f2, col_f3 = st.columns(3)
with col_f1:
    st.info("🤖 **AI Agents**\nIntelligent issue analysis")
with col_f2:
    st.info("🔍 **Knowledge Search**\nSmart solution matching")
with col_f3:
    st.info("⚡ **Real-time**\nInstant customer support")

st.success("🎯 This demonstrates the complete agentic AI support system running on OpenShift with full functionality!")
PYEOF
          
          # Verify file
          echo "📋 Verifying app creation..."
          ls -la app.py
          echo "First few lines:"
          head -10 app.py
          
          # Start streamlit
          echo "🚀 Starting Streamlit server..."
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

echo "🚀 Applying fixed deployment..."
oc apply -f fixed-streamlit.yaml

# Clean up
rm fixed-streamlit.yaml

echo "⏳ Waiting for deployment..."
oc rollout status deployment/ai-support-app -n agentic-ai-demo --timeout=300s

echo ""
echo "📊 Deployment status:"
oc get pods -n agentic-ai-demo -l app=ai-support-app

echo ""
echo "🌐 Your demo should now be working at:"
APP_ROUTE=$(oc get route ai-support-route -n agentic-ai-demo -o jsonpath='{.spec.host}' 2>/dev/null)
if [ -n "$APP_ROUTE" ]; then
    echo "   https://$APP_ROUTE"
else
    echo "   Route not ready yet"
fi

echo ""
echo "🔍 Monitor startup:"
echo "   oc logs -f deployment/ai-support-app -n agentic-ai-demo"

echo ""
echo "✅ Syntax error should now be fixed!"