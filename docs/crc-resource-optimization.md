# CRC Resource Optimization Guide

## 🎯 Problem: CRC Resource Limitations

OpenShift Local (CRC) has limited resources, and Weaviate vector database is quite resource-intensive. This guide provides strategies to run the demo within CRC constraints.

## 💾 CRC Resource Requirements

### Minimum CRC Configuration
```bash
# Check current settings
crc config get memory
crc config get cpus

# Recommended minimal settings
crc config set memory 6144    # 6GB (minimum)
crc config set cpus 4         # 4 cores
crc config set disk-size 60   # 60GB disk

# Apply changes
crc stop
crc start
```

### Resource Comparison

| **Component** | **Full Version** | **Minimal Version** |
|---------------|------------------|---------------------|
| **Weaviate** | 1GB RAM, 500m CPU | ❌ Removed |
| **API Service** | 512MB RAM, 250m CPU | 256MB RAM, 200m CPU |
| **Streamlit App** | 1GB RAM, 500m CPU | 512MB RAM, 400m CPU |
| **Ollama** | 4GB RAM, 2 CPU | ❌ Removed |
| **Total** | ~6.5GB RAM, 3.25 CPU | ~0.8GB RAM, 0.6 CPU |

## 🚀 Solution Approaches

### Option 1: Minimal CRC Deployment (Recommended)

Use the resource-optimized deployment that removes heavy components:

```bash
# Use the minimal deployment script
chmod +x deploy-crc-minimal.sh
./deploy-crc-minimal.sh
```

**What's Removed:**
- ❌ Weaviate vector database
- ❌ Ollama LLM service  
- ❌ CrewAI agents (simplified logic)

**What's Included:**
- ✅ Customer data management
- ✅ In-memory knowledge base with keyword search
- ✅ Troubleshooting guides
- ✅ Ticket creation system
- ✅ Web interface demo
- ✅ REST API with documentation

### Option 2: Hybrid Approach

Run some services locally and others in CRC:

```bash
# Run locally (requires more local resources)
podman run -d --name weaviate -p 8081:8080 \
  -e AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true \
  semitechnologies/weaviate:latest

podman run -d --name ollama-llm -p 11434:11434 \
  ollama/ollama serve

# Deploy only lightweight components to CRC
oc apply -f k8s/crc-api-only.yaml
```

### Option 3: Mock Everything

Create a fully mocked version that demonstrates the concept without real AI:

```bash
# Deploy the demo version
./deploy-crc-minimal.sh
```

This version uses simulated AI responses and keyword-based search instead of vector embeddings.

## 🔧 CRC Optimization Tips

### 1. Increase CRC Resources

```bash
# Stop CRC
crc stop

# Increase resources (adjust based on your Mac's capacity)
crc config set memory 8192      # 8GB if you have 16GB+ total RAM
crc config set cpus 4           # Use 4 cores
crc config set disk-size 80     # 80GB disk space

# Start with new resources
crc start
```

### 2. Clean Up CRC

```bash
# Remove unused projects
oc get projects
oc delete project <unused-project-name>

# Clean up unused images
oc adm prune images --confirm

# Check resource usage
oc adm top nodes
oc adm top pods --all-namespaces
```

### 3. Monitor Resource Usage

```bash
# Check CRC resource usage
crc console --url   # Open web console
# Navigate to Observe > Dashboards > Compute Resources

# Command line monitoring
oc adm top nodes
oc adm top pods -n agentic-ai-demo

# Check pod resource limits
oc describe pods -n agentic-ai-demo
```

## 📊 Performance Comparison

### Full Version vs Minimal Version

| **Feature** | **Full Version** | **Minimal Version** |
|-------------|------------------|---------------------|
| **Vector Search** | ✅ Weaviate embeddings | ❌ Keyword matching |
| **AI Agents** | ✅ CrewAI multi-agent | ❌ Simulated responses |
| **LLM Integration** | ✅ Ollama/Llamastack | ❌ Mock responses |
| **Memory Usage** | 6.5GB+ | <1GB |
| **CPU Usage** | 3+ cores | <1 core |
| **Startup Time** | 5-10 minutes | 1-2 minutes |
| **Demo Value** | Full AI showcase | Concept demonstration |

## 🎯 Demo Strategy

### For Stakeholder Presentations

1. **Start with Minimal Version**
   - Quick deployment and demo
   - Shows the UI and workflow
   - Explains the concept clearly

2. **Explain Full Capabilities**
   - Use slides or documentation
   - Show architecture diagrams
   - Describe AI agent behavior

3. **Offer Full Demo**
   - "The full version with AI agents runs on a larger cluster"
   - "Here's what the AI would actually do..."

### Demo Script

```markdown
"This is our AI-powered support system running on OpenShift. 

Let me show you a customer interaction:
- Enter 'I'm customer CUST123 and my internet is slow'
- Watch as it retrieves customer data
- See the knowledge base search in action
- Observe troubleshooting recommendations
- Note the automatic ticket creation

In the full version, AI agents would:
- Use vector similarity search instead of keywords
- Employ multi-agent reasoning with CrewAI
- Generate dynamic responses with LLM models
- Learn from interactions over time"
```

## 🛠️ Troubleshooting CRC Issues

### Common Problems

#### 1. "Not enough memory" error
```bash
# Check available memory on your Mac
vm_stat | grep "Pages free"

# Increase CRC memory if Mac has capacity
crc config set memory 6144
crc stop && crc start
```

#### 2. Pods stuck in "Pending" state
```bash
# Check node resources
oc describe nodes

# Check pod events
oc describe pod <pod-name> -n agentic-ai-demo

# Solution: Reduce resource requests or increase CRC memory
```

#### 3. "ImagePullBackOff" errors
```bash
# Check if using correct image names
oc describe pod <pod-name> -n agentic-ai-demo

# For minimal deployment, this shouldn't happen (uses public images)
```

#### 4. CRC won't start
```bash
# Reset CRC completely
crc delete
crc setup
crc start

# Check system resources
top -l 1 | grep "PhysMem"
```

### Recovery Commands

```bash
# Complete reset
oc delete project agentic-ai-demo
crc stop
crc start
./deploy-crc-minimal.sh

# Just restart pods
oc delete pods --all -n agentic-ai-demo

# Check logs
oc logs -f deployment/ai-support-app -n agentic-ai-demo
oc logs -f deployment/support-api -n agentic-ai-demo
```

## 📈 Scaling Strategies

### Local Development → CRC Demo → Production

1. **Local Development**
   ```bash
   # Full feature development with Docker/Podman
   ./setup.sh  # Uses docker-compose
   ```

2. **CRC Demo**
   ```bash
   # Resource-optimized demo
   ./deploy-crc-minimal.sh
   ```

3. **Production OpenShift**
   ```bash
   # Full deployment with proper resources
   ./scripts/deploy.sh  # Uses k8s/ manifests
   ```

## 💡 Alternative Demo Ideas

### 1. Video Demo
Record the full version running locally, then show live minimal version on CRC.

### 2. Split Demo
- Show architecture on slides
- Demonstrate API endpoints with curl
- Run UI demo in CRC
- Explain what AI agents would add

### 3. Progressive Demo
1. Start with minimal CRC version
2. Show it working
3. Explain: "Now imagine this with AI agents..."
4. Use diagrams to show full capabilities

## 🔗 Quick Links

- **Deploy Minimal**: `./deploy-crc-minimal.sh`
- **Check Resources**: `oc adm top nodes`
- **View Logs**: `oc logs -f deployment/ai-support-app -n agentic-ai-demo`
- **Clean Up**: `oc delete project agentic-ai-demo`
- **Reset CRC**: `crc delete && crc setup && crc start`

This approach gives you a working demo that showcases the concept while staying within CRC resource limits! 🚀