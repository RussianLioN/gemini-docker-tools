# Multi-Session AI IDE

Enterprise-grade containerized environment supporting **Gemini**, **Claude**, and **GLM-4.6** with up to **5 concurrent GLM sessions**.

## 🚀 Quick Start

```bash
# Clone and install
git clone https://github.com/RussianLioN/multi-session-ai-ide.git
cd multi-session-ai-ide
./unified-interface/ai-ide-multi.zsh --install

# Auto-detect project and start
ai-ide
```

## 🎯 Features

### 🤖 Multi-AI Support
- **Gemini CLI** - Google's AI for DevOps & Infrastructure
- **Claude Code** - Anthropic's AI for Software Engineering  
- **GLM-4.6** - Z.AI's AI with 5 concurrent sessions max

### 🔄 Session Management
- **Unlimited Gemini & Claude sessions**
- **Up to 5 concurrent GLM sessions**
- **Hot-swapping between sessions**
- **Automatic session persistence**
- **Resource monitoring and limits**

### 🛡️ Enterprise Security
- **Container isolation** between AI providers
- **Zero Trust architecture** - secrets never stored
- **SSH agent forwarding** secure by design
- **API key encryption in memory only**

### 🚀 Performance Optimization
- **Docker layer caching** for fast startups
- **Resource limits** per AI type
- **Health monitoring** with automatic recovery
- **Parallel session execution**

## 📋 Usage Examples

### Auto-Detection (Recommended)
```bash
cd ~/my-project
ai-ide  # Auto-detects project type and suggests best AI
```

### Manual Session Creation
```bash
# Create specific AI sessions
ai-ide --new gemini          # DevOps & Infrastructure
ai-ide --new claude          # Software Engineering
ai-ide --new glm             # General Purpose

# Named sessions
ai-ide --create claude debug-session
ai-ide --create glm frontend-work
```

### Session Management
```bash
ai-ide --list                 # Show all active sessions
ai-ide --switch session-123    # Connect to specific session
ai-ide --status               # System health check
ai-ide --cleanup             # Remove inactive sessions
```

## 🏗️ Architecture

```
Multi-Session AI IDE
├── 🐳 Docker Containers
│   ├── gemini-ide     # Unlimited sessions
│   ├── claude-ide     # Unlimited sessions
│   └── glm-ide        # Max 5 sessions
├── 🔄 Session Manager
│   ├── Registry        # Session tracking
│   ├── Discovery       # Service discovery
│   └── Monitor        # Resource usage
├── 🎛️ Unified Interface
│   ├── Auto-detection  # Project type analysis
│   ├── Smart routing   # AI recommendation
│   └── CLI wrapper    # Single entry point
└── 🚀 Orchestrator
    ├── Docker Compose # Multi-container
    ├── Health checks   # Monitoring
    └── Resource limits # Performance
```

## 🔧 Installation

### Prerequisites
- **Docker** 20.10+ with Docker Compose
- **Node.js** 18+ (for local development)
- **Z.AI API Key** (for GLM-4.6)
- **Google Cloud credentials** (for Gemini)
- **Anthropic API Key** (for Claude)

### Automated Installation
```bash
# Install AI IDE and dependencies
ai-ide --install

# Add to PATH (if not already)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Manual Installation
```bash
# Clone repository
git clone https://github.com/RussianLioN/multi-session-ai-ide.git
cd multi-session-ai-ide

# Make executable
chmod +x unified-interface/ai-ide-multi.zsh
chmod +x session-manager/session-manager.sh

# Create symlink
ln -sf $(pwd)/unified-interface/ai-ide-multi.zsh ~/.local/bin/ai-ide
```

## 🔑 Configuration

### Environment Variables
```bash
# GLM-4.6 Configuration
export ZAI_API_KEY="your_zai_api_key"
export GLM_MODEL="glm-4.6"

# Gemini Configuration  
export GOOGLE_CLOUD_PROJECT="your-gcp-project"
export GOOGLE_APPLICATION_CREDENTIALS="path/to/credentials.json"

# Claude Configuration
export ANTHROPIC_API_KEY="your_anthropic_api_key"

# Global Configuration
export PROJECT_ROOT="/path/to/your/projects"
export MAX_CONCURRENT_SESSIONS=10
```

### Provider Setup

#### GLM-4.6 (5 sessions max)
1. Get API key from [Z.AI Platform](https://z.ai/manage-apikey)
2. Set `ZAI_API_KEY` environment variable
3. Start sessions: `ai-ide --new glm`

#### Gemini CLI
1. Install Google Cloud CLI
2. Authenticate: `gcloud auth application-default login`
3. Set project: `gcloud config set project YOUR_PROJECT`
4. Start sessions: `ai-ide --new gemini`

#### Claude Code
1. Install Claude CLI: `npm install -g @anthropic-ai/claude-code`
2. Set API key: `export ANTHROPIC_API_KEY=your_key`
3. Start sessions: `ai-ide --new claude`

## 🎯 AI Provider Selection

| Project Type | Recommended AI | Strengths | Use Cases |
|--------------|-----------------|------------|------------|
| **Docker/Terraform** | 🚀 **Gemini** | DevOps, YAML, Infrastructure | K8s, CloudFormation, CI/CD |
| **Node.js/Python** | 🔧 **Claude** | Code analysis, Debugging | Refactoring, Testing, Architecture |
| **General/Mixed** | 🤖 **GLM-4.6** | Balanced performance | Documentation, Planning, Review |
| **Multi-tasking** | 🔄 **Multi-Session** | Parallel work | Different tasks simultaneously |

## 📊 Performance

### Resource Limits
| AI Provider | Memory Limit | CPU Limit | Max Sessions |
|--------------|---------------|------------|---------------|
| **GLM-4.6** | 3GB | 1.5 cores | 5 |
| **Gemini** | 2GB | 1.0 cores | Unlimited |
| **Claude** | 2GB | 1.0 cores | Unlimited |

### Benchmarks
- **Session startup**: < 5 seconds (cached)
- **Session switching**: < 1 second
- **Memory overhead**: ~200MB per session
- **API response**: < 2 seconds average

## 🛠️ Development

### Building Containers
```bash
# Build all images
docker-compose -f orchestrator/docker-compose.multi.yml build

# Build specific provider
docker build -f containers/glm-ide/Dockerfile -t glm-ide .
```

### Running Tests
```bash
# Session manager tests
bash session-manager/session-manager.sh test

# Integration tests
docker-compose -f orchestrator/docker-compose.multi.yml --profile templates up

# Performance tests
bash tests/performance-test.sh
```

### Contributing
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and test
4. Commit: `git commit -m 'Add amazing feature'`
5. Push: `git push origin feature/amazing-feature`
6. Open Pull Request

## 🔍 Troubleshooting

### Common Issues

#### Session Creation Fails
```bash
# Check Docker status
docker version
docker-compose version

# Check permissions
ls -la ~/.local/bin/ai-ide

# Check environment
ai-ide --health
```

#### GLM Session Limit Reached
```bash
# List active sessions
ai-ide --list

# Cleanup inactive sessions
ai-ide --cleanup

# Delete specific session
ai-ide --delete glm-session-123
```

#### API Connection Issues
```bash
# Test API connectivity
curl -H "Authorization: Bearer $ZAI_API_KEY" https://api.z.ai/health

# Check environment variables
env | grep -E "(ZAI|GOOGLE|ANTHROPIC)"
```

### Debug Mode
```bash
# Enable verbose logging
export AI_IDE_DEBUG=true
ai-ide --new gemini

# Check session logs
docker logs ai-session-manager
```

## 📚 Advanced Usage

### Custom Resource Profiles
```yaml
# orchestrator/custom-profiles.yml
services:
  glm-heavy:
    image: glm-ide:latest
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'
```

### Session Templates
```bash
# Create template for specific workflows
ai-ide --create claude debugging-template --template debug
ai-ide --create glm code-review --template review
```

### Integration with IDEs
```bash
# VS Code integration
code $(ai-ide --get-workspace)

# JetBrains integration
idea $(ai-ide --get-workspace)
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Support

- **Documentation**: [GitHub Wiki](https://github.com/RussianLioN/multi-session-ai-ide/wiki)
- **Issues**: [GitHub Issues](https://github.com/RussianLioN/multi-session-ai-ide/issues)
- **Discussions**: [GitHub Discussions](https://github.com/RussianLioN/multi-session-ai-ide/discussions)

## 🎉 Contributors

- [@RussianLioN](https://github.com/RussianLioN) - Creator & Maintainer
- [Contributors](https://github.com/RussianLioN/multi-session-ai-ide/graphs/contributors)

---

**Multi-Session AI IDE** - The future of AI-powered development with enterprise-grade reliability and performance. 🚀
