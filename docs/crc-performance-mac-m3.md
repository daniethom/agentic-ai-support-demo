# MacBook Pro M3 Performance Tuning for CRC

## 🔧 Optimal CRC Configuration

### Quick Setup Commands

```bash
# Stop CRC
crc stop

# Apply optimal settings for your M3 MacBook Pro
crc config set memory 16384        # 16GB RAM
crc config set cpus 8              # 8 CPU cores  
crc config set disk-size 100       # 100GB disk
crc config set enable-cluster-monitoring true

# Start with new configuration
crc start
```

## 📊 Resource Allocation Breakdown

| **Component** | **Allocation** | **Percentage** | **Reasoning** |
|---------------|----------------|----------------|---------------|
| **CRC Memory** | 16GB | 44% of 36GB | Optimal for full AI demo with Weaviate + Ollama |
| **CRC CPUs** | 8 cores | ~50-67% | Excellent performance, leaves cores for host |
| **CRC Disk** | 100GB | 39% of 256GB | Plenty for images, logs, persistent storage |
| **Host Reserve** | 20GB RAM | 56% | Comfortable buffer for macOS + apps |

## 🎯 Configuration Variants

### Maximum Performance (Demo/Development)
```bash
crc config set memory 20480        # 20GB RAM
crc config set cpus 10             # 10 CPU cores
crc config set disk-size 120       # 120GB disk
```
*Use for intensive AI workloads or when showcasing full capabilities*

### Balanced (Daily Use)
```bash
crc config set memory 16384        # 16GB RAM  
crc config set cpus 8              # 8 CPU cores
crc config set disk-size 100       # 100GB disk
```
*Recommended default - great performance with room for other work*

### Conservative (Multi-tasking)
```bash
crc config set memory 12288        # 12GB RAM
crc config set cpus 6              # 6 CPU cores  
crc config set disk-size 80        # 80GB disk
```
*Use when running multiple VMs or resource-intensive apps*

## ⚡ M3-Specific Optimizations

### macOS Settings for Best Performance

1. **Energy Settings**
   ```bash
   # Set high performance mode (requires admin)
   sudo pmset -a lowpowermode 0
   sudo pmset -a powernap 0
   
   # Or via System Settings:
   # System Settings > Battery > Options > Optimize video streaming while on battery: Off
   ```

2. **Memory Management**
   ```bash
   # Check memory pressure
   memory_pressure
   
   # Monitor swap usage
   sysctl vm.swapusage
   ```

3. **Thermal Management**
   ```bash
   # Monitor CPU temperature (requires additional tools)
   # Install: brew install osx-cpu-temp
   osx-cpu-temp
   ```

### Podman Configuration for M3

```bash
# Optimize Podman for Apple Silicon
podman machine set --memory 4096 --cpus 4 podman-machine-default

# Use Apple's built-in virtualization
export CONTAINERS_MACHINE_PROVIDER=applehv
```

## 🚀 Expected Performance with Your Setup

### Full AI Demo Capabilities
✅ **Weaviate Vector Database**: Smooth vector operations with 16GB RAM  
✅ **Ollama LLM Models**: Can run 7B-13B parameter models efficiently  
✅ **CrewAI Multi-Agents**: Parallel agent execution with 8 cores  
✅ **Concurrent Users**: Support multiple demo sessions  
✅ **Fast Startup**: Pods ready in 30-60 seconds  

### Deployment Options

| **Deployment** | **RAM Usage** | **CPU Usage** | **Startup Time** | **Demo Quality** |
|----------------|---------------|---------------|------------------|------------------|
| **Full Demo** | ~8-12GB | ~4-6 cores | 3-5 minutes | 🌟🌟🌟🌟🌟 |
| **Standard** | ~4-6GB | ~2-3 cores | 2-3 minutes | 🌟🌟🌟🌟 |
| **Minimal** | ~1-2GB | ~1-2 cores | 1-2 minutes | 🌟🌟🌟 |

## 🛠️ Monitoring and Maintenance

### Real-time Monitoring

```bash
# CRC resource usage
oc adm top nodes
oc adm top pods --all-namespaces

# macOS system monitoring
top -l 1 | head -10
vm_stat | grep -E "(Pages free|Pages active|Pages inactive)"

# Temperature monitoring (if osx-cpu-temp installed)
osx-cpu-temp
```

### Performance Optimization Commands

```bash
# Clean up unused resources
crc cleanup
oc adm prune images --confirm

# Restart CRC for fresh state
crc stop && crc start

# Check CRC logs for issues
crc logs
```

## 🔥 Troubleshooting M3-Specific Issues

### Common Issues and Solutions

#### 1. **High Memory Pressure**
```bash
# Check memory usage
memory_pressure

# Solutions:
# - Reduce CRC memory: crc config set memory 12288
# - Close unnecessary apps
# - Restart CRC: crc stop && crc start
```

#### 2. **CPU Throttling**
```bash
# Check CPU usage
top -l 1 | grep "CPU usage"

# Solutions:
# - Reduce CPU allocation: crc config set cpus 6
# - Ensure good ventilation
# - Check Activity Monitor for background processes
```

#### 3. **Slow Disk Performance**
```bash
# Check disk space
df -h

# Solutions:
# - Free up disk space: crc cleanup
# - Move large files to external storage
# - Reduce disk allocation if needed
```

#### 4. **Container Startup Issues**
```bash
# Check for M1/M3 compatibility issues
oc describe pod <failing-pod> -n <namespace>

# Solutions:
# - Ensure ARM64-compatible images
# - Use multi-arch images (most modern images)
# - Check image pull policies
```

## 📈 Benchmarking Your Setup

### Performance Tests

```bash
# Test 1: Cluster responsiveness
time oc get pods --all-namespaces

# Test 2: Image pull speed  
time oc run test-pod --image=nginx --rm -it -- /bin/bash

# Test 3: Resource allocation
oc run resource-test --image=stress --rm -it -- stress --cpu 4 --timeout 30s
```

### Expected Results
- **Command response**: < 1 second
- **Pod startup**: 10-30 seconds  
- **Image pull**: 30-90 seconds (depending on image size)
- **Resource allocation**: Immediate

## 🎯 Demo Day Checklist

### Before Your Demo

```bash
# 1. Optimize macOS
- Close unnecessary applications
- Connect power adapter
- Disable sleep mode temporarily

# 2. Prepare CRC
crc stop
crc start  # Fresh start
oc login  # Test connectivity

# 3. Pre-pull images (optional)
oc apply -f k8s/  # Pre-deploy to cache images

# 4. Verify performance
oc adm top nodes
```

### During Demo

- Monitor Activity Monitor for any spikes
- Keep backup minimal deployment ready
- Have terminal ready with useful commands
- Monitor temperature if doing intensive demos

## 🔗 Quick Reference

```bash
# Essential CRC commands for M3 MacBook
crc status                    # Check CRC status
crc config view              # View all settings  
crc console --url            # Get console URL
crc console --credentials    # Get login info
oc adm top nodes             # Monitor resources
memory_pressure              # Check Mac memory pressure
```

Your M3 MacBook Pro is perfectly suited for running the full AI demo with excellent performance! 🚀