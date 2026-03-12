# Dify One-Click Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/caoergou/dify-installer.svg)](https://github.com/caoergou/dify-installer/stargazers)

A simple one-click installer for [Dify](https://github.com/langgenius/dify) Docker deployment. Get Dify up and running in minutes with a single command.

## Features

- **One-liner installation** - Just curl and bash
- **Auto shallow clone** - Downloads only what's needed
- **Interactive configuration** - Smart defaults with guided setup
- **Database selection** - PostgreSQL or MySQL
- **Vector database selection** - Weaviate, Qdrant, Milvus, Chroma, or pgvector
- **Storage options** - Local, S3, Azure, GCS, or Aliyun OSS
- **SSL support** - Let's Encrypt or custom certificates
- **Email configuration** - SMTP, Gmail, SendGrid, or Resend

## Quick Start

```bash
curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install.sh | bash
```

That's it! The installer will guide you through the rest.

### Non-interactive Mode

For automated deployments, use the `--yes` flag:

```bash
curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install.sh | bash -s -- --yes
```

## For Users in China

If you're in China, use the optimized version with Gitee mirror for faster downloads:

```bash
curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install_cn.sh | bash
```

## Requirements

- **Docker** and **Docker Compose** installed
- **2+ CPU cores** recommended
- **4GB+ RAM** recommended
- **Ports 80, 443** available (configurable)

## Usage

### Interactive Mode (Recommended)

Run the installer and follow the prompts:

```bash
./install.sh
```

### Non-interactive Mode

Use all recommended defaults without prompts:

```bash
./install.sh --yes
# or
./install.sh -y
```

### Show Help

```bash
./install.sh --help
```

## Configuration Options

The installer will ask about:

| Option | Description | Default |
|--------|-------------|---------|
| Deployment Type | Private (localhost) or Public (domain) | Private |
| HTTP Port | Web access port | 80 |
| Database | PostgreSQL or MySQL | PostgreSQL |
| Vector DB | Weaviate, Qdrant, Milvus, Chroma, pgvector | Weaviate |
| Storage | Local, S3, Azure, GCS, Aliyun OSS | Local |
| Email | SMTP configuration (optional) | Disabled |

All secrets are auto-generated securely.

## After Installation

Once installed, Dify will be available at `http://localhost` (or your configured domain).

### Quick Commands

Run these from the installation directory:

```bash
# View logs
docker compose logs -f

# Stop services
docker compose down

# Start services
docker compose up -d

# Check status
docker compose ps
```

## What Gets Installed

The installer clones the official [Dify repository](https://github.com/langgenius/dify) and sets up:

- **API** - Backend services
- **Web** - Frontend application
- **Worker** - Background task processor
- **Nginx** - Reverse proxy
- **Database** - PostgreSQL or MySQL
- **Redis** - Caching and message queue
- **Vector DB** - Your choice of Weaviate, Qdrant, Milvus, Chroma, or pgvector

## Security Features

- **RCE Protection** - Verifies git repository authenticity
- **Secure Secrets** - Uses cryptographically secure random generation
- **File Permissions** - Sets restrictive permissions on `.env` file
- **Directory Safety** - Checks for ownership before operations

## Related Links

- [Dify Official Repository](https://github.com/langgenius/dify)
- [Dify Documentation](https://docs.dify.ai)
- [Dify Cloud](https://cloud.dify.ai) - Managed hosting option

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- The [Dify Team](https://github.com/langgenius) for creating an amazing LLM application platform
- All contributors who help improve this installer

---

**Note**: This is an independent community project. For official Dify support, please visit the [official repository](https://github.com/langgenius/dify).
