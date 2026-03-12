# Dify Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**One command to deploy Dify.** No complex configuration, no manual cloning.

```bash
curl -sSL https://dify.ai/install | bash
# Or: curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install.sh | bash
```

## What is Dify?

[Dify](https://github.com/langgenius/dify) is an open-source LLM application development platform. This installer gets you running in minutes.

## One-Line Install

| Region | Command |
|--------|---------|
| Global | `curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install.sh \| bash` |
| China | `curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install_cn.sh \| bash` |

## What You Get

- Interactive setup with smart defaults
- PostgreSQL or MySQL
- Vector DB: Weaviate, Qdrant, Milvus, Chroma, pgvector
- Storage: Local, S3, Azure, GCS, Aliyun OSS
- SSL with Let's Encrypt or custom certs

## Requirements

- Docker + Docker Compose
- 2+ CPU cores, 4GB+ RAM
- Ports 80, 443 available

## Quick Commands

```bash
./install.sh           # Interactive setup
./install.sh --yes     # Use all defaults
./install.sh --help    # Show help
```

After installation:
```bash
docker compose logs -f   # View logs
docker compose down      # Stop
docker compose up -d     # Start
```

## Links

- [Dify](https://github.com/langgenius/dify) - Official repository
- [Docs](https://docs.dify.ai) - Documentation
- [Cloud](https://cloud.dify.ai) - Managed hosting

## License

MIT
