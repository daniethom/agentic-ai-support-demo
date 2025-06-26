#!/bin/bash

echo "🔧 Fixing Streamlit File Creation Issue"
echo "====================================="

echo "🛑 Stopping current Streamlit deployment..."
oc scale deployment ai-support-app --replicas=0 -n agentic-ai-demo

echo "⏳ Waiting for pod to terminate..."
sleep 10

echo "🔧 Creating fixed Streamlit deployment..."

cat > streamlit-fixed.yaml << 'EOF'
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
        - name: PATH
          value: "/tmp/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        command: ["/bin/bash"]
        args:
        - -c
        - |
          echo "🚀 Starting Streamlit with fixed permissions..."
          
          # Create writable directories
          mkdir -p /tmp/.local/bin /tmp/.cache /tmp/app /tmp/.streamlit
          cd /tmp/app
          
          # Install dependencies
          echo "📦 Installing Streamlit..."
          pip install --user --cache-dir=/tmp/.cache streamlit requests
          
          # Create Streamlit config in a writable location
          echo "⚙️  Creating Streamlit config..."
          cat > /tmp/.streamlit/config.toml << 'CONFIGEOF'
          [server]
          port = 8501
          address = "0.0.0.0"
          headless = true
          enableCORS = false
          enableXsrfProtection = false
          fileWatcherType = "none"
          
          [browser]
          gatherUsageStats = false
          CONFIGEOF
          
          # Create the Python application file using printf to avoid permission issues
          echo "🎨 Creating Streamlit application..."
          printf '%s\n' \
          'import streamlit as st' \
          'import requests' \
          'import json' \
          'import time' \
          '' \
          'st.set_page_config(page_title="🤖 AI Support", layout="wide")' \
          '' \
          '# Header' \
          'st.markdown("""' \
          '<div style="background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);' \
          '            padding: 2rem; border-radius: 10px; color: white; text-align: center; margin-bottom: 2rem;">' \
          '    <h1>🤖 AI Support System</h1>' \
          '    <p>OpenShift Compatible Demo - Full Functionality</p>' \
          '</div>' \
          '""", unsafe_allow_html=True)' \
          '' \
          '# System status sidebar' \
          'with st.sidebar:' \
          '    st.markdown("### 🔧 System Status")' \
          '    ' \
          '    # Check API service' \
          '    try:' \
          '        api_resp = requests.get("http://support-api:8000/health", timeout=3)' \
          '        if api_resp.status_code == 200:' \
          '            st.success("🟢 API Service")' \
          '            health_data = api_resp.json()' \
          '            st.caption(f"Mode: {health_data.get(\"mode\", \"unknown\")}")' \
          '        else:' \
          '            st.error("🔴 API Service")' \
          '    except:' \
          '        st.warning("🟡 API Service")' \
          '    ' \
          '    # Check Weaviate' \
          '    try:' \
          '        weaviate_resp = requests.get("http://weaviate:8080/v1/meta", timeout=3)' \
          '        if weaviate_resp.status_code == 200:' \
          '            st.success("🟢 Vector DB")' \
          '        else:' \
          '            st.error("🔴 Vector DB")' \
          '    except:' \
          '        st.warning("🟡 Vector DB")' \
          '    ' \
          '    # Check Ollama' \
          '    try:' \
          '        ollama_resp = requests.get("http://ollama:11434/api/tags", timeout=3)' \
          '        if ollama_resp.status_code == 200:' \
          '            st.success("🟢 LLM Service")' \
          '            models = ollama_resp.json().get("models", [])' \
          '            st.caption(f"Models: {len(models)}")' \
          '        else:' \
          '            st.info("🔵 LLM Loading")' \
          '    except:' \
          '        st.info("🔵 LLM Starting")' \
          '    ' \
          '    st.markdown("---")' \
          '    st.markdown("### ✨ Demo Features")' \
          '    st.markdown("✅ Customer Data Lookup")' \
          '    st.markdown("✅ AI Issue Analysis")' \
          '    st.markdown("✅ Knowledge Base Search")' \
          '    st.markdown("✅ Intelligent Troubleshooting")' \
          '    st.markdown("✅ Automated Ticketing")' \
          '    st.markdown("✅ Device Management")' \
          '    if "ollama" in str(st.session_state.get("services", {})):' \
          '        st.markdown("✅ LLM Integration")' \
          '' \
          '# Main interface' \
          'col1, col2 = st.columns([2, 1])' \
          '' \
          'with col1:' \
          '    st.markdown("### 🎯 AI-Powered Customer Support")' \
          '    ' \
          '    inquiry = st.text_area(' \
          '        "Describe your technical issue:",' \
          '        height=150,' \
          '        placeholder="e.g., I'\''m customer CUST123 and my internet connection is very slow today..."' \
          '    )' \
          '    ' \
          '    col_a, col_b = st.columns(2)' \
          '    with col_a:' \
          '        if st.button("🤖 Full AI Analysis", type="primary"):' \
          '            if inquiry.strip():' \
          '                process_with_ai(inquiry)' \
          '            else:' \
          '                st.warning("Please describe your issue first.")' \
          '    ' \
          '    with col_b:' \
          '        if st.button("🔍 Quick Search"):' \
          '            if inquiry.strip():' \
          '                quick_search(inquiry)' \
          '            else:' \
          '                st.warning("Enter search terms.")' \
          '' \
          'with col2:' \
          '    st.markdown("### 📋 Demo Test Cases")' \
          '    ' \
          '    test_scenarios = [' \
          '        ("🐌 Speed Issues", "I'\''m customer CUST123 and my internet is extremely slow"),' \
          '        ("🔐 Login Problems", "Customer CUST456 - cannot access my account"),' \
          '        ("📡 Outage", "CUST789 - internet connection completely down"),' \
          '        ("💳 Billing", "CUST000 - question about recent charges")' \
          '    ]' \
          '    ' \
          '    for i, (title, query) in enumerate(test_scenarios):' \
          '        if st.button(title, key=f"scenario_{i}"):' \
          '            st.session_state.demo_query = query' \
          '    ' \
          '    if "demo_query" in st.session_state:' \
          '        st.text_area("Selected test case:", value=st.session_state.demo_query, height=100)' \
          '' \
          'def process_with_ai(inquiry):' \
          '    """Process inquiry with full AI analysis"""' \
          '    st.markdown("---")' \
          '    st.markdown("## 🤖 AI Agent Processing Pipeline")' \
          '    ' \
          '    import re' \
          '    cust_match = re.search(r"CUST\d+", inquiry.upper())' \
          '    ' \
          '    if cust_match:' \
          '        cust_id = cust_match.group()' \
          '        ' \
          '        # Step 1: Customer Analysis' \
          '        with st.expander("👤 Tier 1 Agent: Customer Analysis", expanded=True):' \
          '            with st.spinner("Analyzing customer data..."):' \
          '                time.sleep(1)' \
          '                ' \
          '                try:' \
          '                    response = requests.get(f"http://support-api:8000/account_status/{cust_id}", timeout=5)' \
          '                    if response.status_code == 200:' \
          '                        customer = response.json()' \
          '                        ' \
          '                        col1, col2, col3 = st.columns(3)' \
          '                        with col1:' \
          '                            st.metric("Customer", customer["name"])' \
          '                            st.metric("Plan", customer["plan"])' \
          '                        with col2:' \
          '                            status = customer["service_status"]' \
          '                            icon = "🟢" if status == "Active" else "🔴"' \
          '                            st.metric("Status", f"{icon} {status}")' \
          '                            st.metric("Device", customer.get("device_id", "N/A"))' \
          '                        with col3:' \
          '                            st.metric("Issues", len(customer["current_issues"]))' \
          '                            if customer["current_issues"]:' \
          '                                st.warning(f"⚠️ Active: {\"、\".join(customer[\"current_issues\"])}")' \
          '                    else:' \
          '                        st.error(f"❌ Customer {cust_id} not found")' \
          '                except Exception as e:' \
          '                    st.error(f"❌ Error: {str(e)}")' \
          '        ' \
          '        # Step 2: AI Analysis' \
          '        with st.expander("🧠 AI Agent: Issue Classification", expanded=True):' \
          '            with st.spinner("AI agents analyzing..."):' \
          '                time.sleep(2)' \
          '                ' \
          '                try:' \
          '                    ai_resp = requests.post(' \
          '                        "http://support-api:8000/ai_agent_analysis",' \
          '                        json={"customer_id": cust_id, "query": inquiry},' \
          '                        timeout=5' \
          '                    )' \
          '                    if ai_resp.status_code == 200:' \
          '                        ai_data = ai_resp.json()' \
          '                        analysis = ai_data["agent_response"]' \
          '                        ' \
          '                        col1, col2, col3 = st.columns(3)' \
          '                        with col1:' \
          '                            st.metric("Priority", analysis["customer_priority"].upper())' \
          '                        with col2:' \
          '                            st.metric("Category", analysis["issue_category"].title())' \
          '                        with col3:' \
          '                            st.metric("Confidence", f"{analysis[\"confidence\"]:.1%}")' \
          '                        ' \
          '                        st.success(f"✅ AI Recommendation: {analysis[\"recommended_action\"].replace(\"_\", \" \").title()}")' \
          '                        st.info(f"💬 Agent Response: {analysis[\"ai_response\"]}")' \
          '                    else:' \
          '                        st.error("❌ AI analysis failed")' \
          '                except Exception as e:' \
          '                    st.error(f"❌ AI error: {str(e)}")' \
          '        ' \
          '        # Step 3: Knowledge Search' \
          '        with st.expander("🔍 Knowledge Base Search", expanded=True):' \
          '            with st.spinner("Searching knowledge base..."):' \
          '                time.sleep(1)' \
          '                ' \
          '                try:' \
          '                    kb_resp = requests.post(' \
          '                        "http://support-api:8000/knowledge_search",' \
          '                        json={"query": inquiry},' \
          '                        timeout=5' \
          '                    )' \
          '                    if kb_resp.status_code == 200:' \
          '                        kb_data = kb_resp.json()' \
          '                        ' \
          '                        if kb_data["results"]:' \
          '                            for i, result in enumerate(kb_data["results"][:2]):' \
          '                                st.markdown(f"**📚 Result {i+1}** (Score: {result.get(\"score\", 0):.2f})")' \
          '                                st.write(result.get("content", "No content"))' \
          '                                st.markdown("---")' \
          '                        else:' \
          '                            st.warning("🔍 No relevant articles found")' \
          '                    else:' \
          '                        st.error("❌ Knowledge search failed")' \
          '                except Exception as e:' \
          '                    st.error(f"❌ Search error: {str(e)}")' \
          '        ' \
          '        # Step 4: Actions' \
          '        with st.expander("🛠️ Available Actions", expanded=True):' \
          '            col1, col2, col3 = st.columns(3)' \
          '            ' \
          '            with col1:' \
          '                if st.button("📋 Create Ticket"):' \
          '                    try:' \
          '                        ticket_resp = requests.post(' \
          '                            "http://support-api:8000/create_ticket",' \
          '                            json={"customer_id": cust_id, "issue_summary": inquiry[:100]},' \
          '                            timeout=5' \
          '                        )' \
          '                        if ticket_resp.status_code == 200:' \
          '                            ticket = ticket_resp.json()' \
          '                            st.success(f"✅ Ticket: {ticket[\"ticket_id\"]}")' \
          '                            st.info(f"Priority: {ticket[\"priority\"]}")' \
          '                        else:' \
          '                            st.error("❌ Ticket creation failed")' \
          '                    except Exception as e:' \
          '                        st.error(f"❌ Error: {str(e)}")' \
          '            ' \
          '            with col2:' \
          '                device_id = customer.get("device_id", "UNKNOWN")' \
          '                if st.button("🔄 Reboot Device"):' \
          '                    try:' \
          '                        reboot_resp = requests.post(f"http://support-api:8000/reboot_device/{device_id}", timeout=5)' \
          '                        if reboot_resp.status_code == 200:' \
          '                            st.success("✅ Device reboot initiated")' \
          '                        else:' \
          '                            st.error("❌ Reboot failed")' \
          '                    except Exception as e:' \
          '                        st.error(f"❌ Error: {str(e)}")' \
          '            ' \
          '            with col3:' \
          '                if "slow" in inquiry.lower():' \
          '                    if st.button("📋 Get Troubleshooting"):' \
          '                        try:' \
          '                            ts_resp = requests.get("http://support-api:8000/troubleshooting_steps/internet_slow", timeout=5)' \
          '                            if ts_resp.status_code == 200:' \
          '                                guide = ts_resp.json()' \
          '                                st.success(f"✅ {guide[\"issue\"]}")' \
          '                                for step in guide["steps"]:' \
          '                                    st.write(f"• {step}")' \
          '                            else:' \
          '                                st.error("❌ Guide not found")' \
          '                        except Exception as e:' \
          '                            st.error(f"❌ Error: {str(e)}")' \
          '    else:' \
          '        st.warning("⚠️ Please include a customer ID (e.g., CUST123) for full AI analysis.")' \
          '' \
          'def quick_search(query):' \
          '    """Quick knowledge base search"""' \
          '    st.markdown("---")' \
          '    st.markdown("## 🔍 Quick Knowledge Search")' \
          '    ' \
          '    with st.spinner("Searching..."):' \
          '        try:' \
          '            kb_resp = requests.post(' \
          '                "http://support-api:8000/knowledge_search",' \
          '                json={"query": query},' \
          '                timeout=5' \
          '            )' \
          '            if kb_resp.status_code == 200:' \
          '                kb_data = kb_resp.json()' \
          '                ' \
          '                if kb_data["results"]:' \
          '                    for result in kb_data["results"]:' \
          '                        with st.expander(f"📚 {result.get(\"title\", \"Knowledge Article\")}"):' \
          '                            st.write(result.get("content", "No content"))' \
          '                else:' \
          '                    st.warning("🔍 No relevant articles found")' \
          '            else:' \
          '                st.error("❌ Search failed")' \
          '        except Exception as e:' \
          '            st.error(f"❌ Error: {str(e)}")' \
          '' \
          '# Footer' \
          'st.markdown("---")' \
          'col1, col2, col3 = st.columns(3)' \
          '' \
          'with col1:' \
          '    st.info("🤖 **AI Agents**\\nMulti-tier intelligent analysis")' \
          'with col2:' \
          '    st.info("🔍 **Smart Search**\\nVector-based knowledge retrieval")' \
          'with col3:' \
          '    st.info("⚡ **Real-time**\\nInstant analysis and actions")' \
          > demo_app.py
          
          echo "🚀 Starting Streamlit application..."
          export STREAMLIT_SERVER_HEADLESS=true
          export STREAMLIT_CONFIG_DIR=/tmp/.streamlit
          
          # Use the full path to streamlit
          /tmp/.local/bin/streamlit run demo_app.py --server.port=8501 --server.address=0.0.0.0
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
EOF

echo "🚀 Applying fixed Streamlit deployment..."
oc apply -f streamlit-fixed.yaml

# Clean up
rm streamlit-fixed.yaml

echo "⏳ Waiting for Streamlit to start..."
oc rollout status deployment/ai-support-app -n agentic-ai-demo --timeout=300s

echo ""
echo "📊 Deployment Status:"
oc get pods -n agentic-ai-demo -l app=ai-support-app

echo ""
echo "🔍 To monitor progress:"
echo "   oc logs -f deployment/ai-support-app -n agentic-ai-demo"

echo ""
echo "🌐 Application URL:"
AI_ROUTE=$(oc get route ai-support-route -n agentic-ai-demo -o jsonpath='{.spec.host}' 2>/dev/null)
if [ -n "$AI_ROUTE" ]; then
    echo "   🤖 AI Support Demo: https://$AI_ROUTE"
else
    echo "   ⚠️  Route not ready yet"
fi

echo ""
echo "✅ Fixed Streamlit deployment complete!"