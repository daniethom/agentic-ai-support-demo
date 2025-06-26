#!/bin/bash

echo "🚀 Configuring CRC for MacBook Pro M3 (36GB RAM, 256GB Disk)"
echo "========================================================="

# Stop CRC if running
echo "🛑 Stopping CRC to apply new configuration..."
crc stop 2>/dev/null || echo "CRC was not running"

# Optimal settings for MacBook Pro M3 with 36GB RAM
echo "⚙️  Applying optimal CRC configuration..."

# Memory: Use 16GB (about 44% of your total RAM)
# This leaves 20GB for macOS and other applications
crc config set memory 16384

# CPUs: Use 6-8 cores (M3 Pro has 12 cores, M3 Max has 16 cores)
# This provides excellent performance while leaving cores for the host
crc config set cpus 8

# Disk: Use 100GB (about 40% of your 256GB disk)
# This provides plenty of space for container images and persistent storage
crc config set disk-size 100

# Enable cluster monitoring (you have the resources for it)
crc config set enable-cluster-monitoring true

# Show the configuration
echo ""
echo "📊 Applied CRC Configuration:"
echo "   Memory: $(crc config get memory)MB (16GB)"
echo "   CPUs: $(crc config get cpus) cores"
echo "   Disk: $(crc config get disk-size)GB"
echo "   Cluster Monitoring: $(crc config get enable-cluster-monitoring)"
echo ""

# Explain the resource allocation
echo "💾 Resource Allocation Strategy:"
echo "   Total Mac RAM: 36GB"
echo "   ├── CRC VM: 16GB (44%)"
echo "   ├── macOS: ~12GB (33%)"
echo "   └── Available: ~8GB (23%) for other apps"
echo ""
echo "   M3 CPU Cores: 12-16 (depending on Pro/Max)"
echo "   ├── CRC: 8 cores"
echo "   └── Host: 4-8 cores remaining"
echo ""
echo "   SSD Storage: 256GB"
echo "   ├── CRC: 100GB (39%)"
echo "   └── Available: ~156GB for macOS and apps"
echo ""

# Start CRC with new configuration
echo "🚀 Starting CRC with optimized settings..."
crc start

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ CRC started successfully with optimized configuration!"
    echo ""
    
    # Show cluster info
    echo "🌐 Cluster Information:"
    eval $(crc oc-env)
    oc cluster-info
    
    echo ""
    echo "📈 Resource Status:"
    oc adm top nodes 2>/dev/null || echo "Node metrics not yet available"
    
    echo ""
    echo "🎯 Performance Expectations:"
    echo "   ✅ Full Weaviate vector database support"
    echo "   ✅ Ollama LLM models (with sufficient resources)"
    echo "   ✅ Multiple concurrent applications"
    echo "   ✅ Fast pod startup times"
    echo "   ✅ Smooth web interface performance"
    echo "   ✅ Cluster monitoring and logging"
    
    echo ""
    echo "🚀 Ready for Full Demo Deployment:"
    echo "   ./deploy-crc.sh          # Full deployment with all features"
    echo "   ./deploy-crc-minimal.sh  # Lightweight deployment (if needed)"
    
    echo ""
    echo "🌐 Access Points:"
    echo "   OpenShift Console: $(crc console --url)"
    echo "   Console Credentials: $(crc console --credentials)"
    
else
    echo ""
    echo "❌ CRC failed to start. Troubleshooting options:"
    echo ""
    echo "1. 🔍 Check system resources:"
    echo "   vm_stat | grep 'Pages free'"
    echo "   sysctl hw.memsize"
    echo ""
    echo "2. 🧹 Clean up and retry:"
    echo "   crc delete"
    echo "   crc setup"
    echo "   crc start"
    echo ""
    echo "3. 📉 Try conservative settings:"
    echo "   crc config set memory 12288  # 12GB"
    echo "   crc config set cpus 6"
    echo "   crc start"
fi

echo ""
echo "💡 Pro Tips for Your M3 MacBook:"
echo ""
echo "🔥 Performance Optimization:"
echo "   • Keep macOS updated for M3 optimizations"
echo "   • Close unnecessary apps before heavy CRC usage"
echo "   • Use Activity Monitor to track resource usage"
echo "   • Consider using external storage for container images"
echo ""
echo "🌡️  Temperature Management:"
echo "   • Monitor CPU temperature during heavy workloads"
echo "   • Ensure proper ventilation"
echo "   • Use 'crc stop' when not actively demoing"
echo ""
echo "⚡ Battery Considerations:"
echo "   • CRC is CPU/RAM intensive - use power adapter"
echo "   • Adjust energy settings: System Settings > Battery > Options"
echo "   • Consider 'Prevent computer from sleeping' during demos"
echo ""
echo "🔄 Maintenance Commands:"
echo "   crc status                    # Check CRC status"
echo "   crc config view              # View all settings"
echo "   oc adm top nodes             # Monitor resource usage"
echo "   crc logs                     # View CRC logs"
echo "   crc cleanup                  # Clean unused resources"