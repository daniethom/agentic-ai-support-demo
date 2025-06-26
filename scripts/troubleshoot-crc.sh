#!/bin/bash

echo "🔍 CRC Troubleshooting Script"
echo "=============================="

# Check CRC status
echo "📊 CRC Status:"
crc status
echo ""

# Check if logged in
echo "🔐 OpenShift Login Status:"
oc whoami 2>/dev/null || echo "❌ Not logged in to OpenShift"
echo ""

# Check project
echo "📦 Current Project:"
oc project 2>/dev/null || echo "❌ No project selected"
echo ""

# Check pods if in the right project
if oc get project agentic-ai-demo >/dev/null 2>&1; then
    echo "🏃 Pod Status in agentic-ai-demo:"
    oc get pods -n agentic-ai-demo
    echo ""
    
    echo "📋 Pod Details:"
    for pod in $(oc get pods -n agentic-ai-demo -o name 2>/dev/null); do
        echo "--- $pod ---"
        oc describe $pod -n agentic-ai-demo | grep -A5 -B5 "Events:\|State:\|Ready:"
        echo ""
    done
    
    echo "🌐 Routes:"
    oc get routes -n agentic-ai-demo
    echo ""
    
    echo "🔍 Services:"
    oc get services -n agentic-ai-demo
    echo ""
else
    echo "⚠️  Project agentic-ai-demo not found"
fi

# Check registry
echo "🏪 Registry Status:"
oc get route default-route -n openshift-image-registry 2>/dev/null || echo "⚠️  Default registry route not found"
echo ""

# Check node resources
echo "💾 Node Resources:"
oc describe nodes | grep -A5 "Allocated resources"
echo ""

# Check events
echo "📰 Recent Events:"
oc get events -n agentic-ai-demo --sort-by='.lastTimestamp' | tail -10
echo ""

# Provide common solutions
echo "🛠️  Common Solutions:"
echo ""
echo "1. 🔄 Restart CRC:"
echo "   crc stop && crc start"
echo ""
echo "2. 🧹 Clean up failed deployment:"
echo "   oc delete project agentic-ai-demo"
echo "   oc new-project agentic-ai-demo"
echo ""
echo "3. 🔐 Re-login to OpenShift:"
echo "   oc login -u kubeadmin -p \$(crc console --credentials | grep kubeadmin | awk '{print \$2}') https://api.crc.testing:6443 --insecure-skip-tls-verify=true"
echo ""
echo "4. 📦 Check image pull secrets:"
echo "   oc get secrets -n agentic-ai-demo"
echo ""
echo "5. 🗂️  View pod logs:"
echo "   oc logs -f deployment/ai-support-app -n agentic-ai-demo"
echo "   oc logs -f deployment/support-api -n agentic-ai-demo"
echo "   oc logs -f deployment/weaviate -n agentic-ai-demo"
echo ""
echo "6. 🏪 Expose registry manually:"
echo "   oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{\"spec\":{\"defaultRoute\":true}}' --type=merge"
echo ""

# Check specific issues
echo "🔎 Checking for specific issues..."
echo ""

# Check if CRC has enough resources
CRC_MEMORY=$(crc config get memory 2>/dev/null || echo "unknown")
CRC_CPUS=$(crc config get cpus 2>/dev/null || echo "unknown")
echo "💻 CRC Resources: Memory=${CRC_MEMORY}MB, CPUs=${CRC_CPUS}"

if [ "$CRC_MEMORY" != "unknown" ] && [ "$CRC_MEMORY" -lt 8192 ]; then
    echo "⚠️  CRC memory is less than 8GB. Consider increasing:"
    echo "   crc config set memory 8192"
    echo "   crc stop && crc start"
fi
echo ""

# Check for ImagePullBackOff
if oc get pods -n agentic-ai-demo 2>/dev/null | grep -q "ImagePullBackOff\|ErrImagePull"; then
    echo "🖼️  Image Pull Issues Detected:"
    echo "   This usually means the images weren't pushed correctly to the registry."
    echo "   Try rebuilding and pushing the images:"
    echo "   ./deploy-crc.sh"
fi
echo ""

# Check for CrashLoopBackOff
if oc get pods -n agentic-ai-demo 2>/dev/null | grep -q "CrashLoopBackOff"; then
    echo "💥 Crash Loop Detected:"
    echo "   Check logs for specific error:"
    echo "   oc logs -f \$(oc get pods -n agentic-ai-demo -o name | head -1) -n agentic-ai-demo"
fi
echo ""

echo "✅ Troubleshooting complete!"
echo ""
echo "🆘 If issues persist:"
echo "   1. Check CRC documentation: https://crc.dev/crc/"
echo "   2. Reset CRC completely: crc delete && crc setup && crc start"
echo "   3. Check system resources (need 8GB+ RAM free)"