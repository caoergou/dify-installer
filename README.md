# Dify Installer - One-Click Docker Deployment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/caoergou/dify-installer?style=social)](https://github.com/caoergou/dify-installer/stargazers)

**Deploy Dify (LLM App Platform) with a single command.** Docker Compose based installation with no manual cloning, no complex configuration.

[中文文档](README_CN.md) | [Dify Official](https://github.com/langgenius/dify)

```bash
curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install.sh | bash
```

---

## What is Dify?

[Dify](https://github.com/langgenius/dify) is an open-source **LLM application development platform** for building AI apps, chatbots, RAG pipelines, and AI agents. Similar to LangChain but with a visual no-code interface.

This installer uses **Docker Compose** to get you running in minutes on any Linux server.

## One-Line Install

| Region | Command |
|--------|---------|
| Global | `curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install.sh \| bash` |
| China  | `curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install_cn.sh \| bash` |

## What You Get

- **Docker Compose deployment** - All services in containers
- Interactive setup with smart defaults
- Database: PostgreSQL or MySQL
- Vector DB: Weaviate, Qdrant, Milvus, Chroma, pgvector
- Storage: Local, S3, Azure, GCS, Aliyun OSS
- SSL: Let's Encrypt or custom certificates

## Requirements

- Docker + Docker Compose installed
- 2+ CPU cores, 4GB+ RAM
- Ports 80, 443 available

## Usage

```bash
./install.sh           # Interactive setup
./install.sh --yes     # Use all defaults
./install.sh --help    # Show help
```

## After Installation

Services are managed via Docker Compose:

```bash
docker compose logs -f   # View logs
docker compose down      # Stop all services
docker compose up -d     # Start all services
docker compose ps        # Check status
```

Access Dify at `http://localhost` (or your configured domain).

## Documentation

- [Advanced Configuration](docs/advanced.md) - Environment variables, performance tuning, SSL
- [Chinese Advanced Docs](docs/advanced_cn.md) - 中文高级配置文档

## Links

- [Dify](https://github.com/langgenius/dify) - Official repository
- [Dify Docs](https://docs.dify.ai) - Official documentation
- [Dify Cloud](https://cloud.dify.ai) - Managed hosting

## License

MIT
