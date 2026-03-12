# Dify 一键安装器 - Docker 部署

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/caoergou/dify-installer?style=social)](https://github.com/caoergou/dify-installer/stargazers)

**一行命令部署 Dify（LLM 应用开发平台）。** 基于 Docker Compose，无需手动克隆，无需复杂配置。国内用户自动使用镜像加速。

[English](README.md) | [Dify 官方仓库](https://github.com/langgenius/dify)

```bash
curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install_cn.sh | bash
```

---

## 什么是 Dify？

[Dify](https://github.com/langgenius/dify) 是开源的 **LLM 应用开发平台**，用于构建 AI 应用、聊天机器人、RAG 知识库和 AI 智能体。类似 LangChain，但提供可视化无代码界面。

本安装器使用 **Docker Compose** 让你在几分钟内完成服务器部署。

## 一键安装

| 地区 | 命令 |
|------|------|
| 国内 | `curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install_cn.sh \| bash` |
| 海外 | `curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install.sh \| bash` |

## 功能特性

- **Docker Compose 部署** - 所有服务运行在容器中
- 交互式配置，智能默认值
- 数据库：PostgreSQL 或 MySQL
- 向量数据库：Weaviate、Qdrant、Milvus、Chroma、pgvector
- 存储：本地、S3、Azure、GCS、阿里云 OSS
- SSL 证书：Let's Encrypt 或自定义

## 系统要求

- 已安装 Docker + Docker Compose
- 2+ CPU 核心，4GB+ 内存
- 端口 80、443 可用

## 使用方法

```bash
./install_cn.sh           # 交互式配置
./install_cn.sh --yes     # 使用默认值
./install_cn.sh --help    # 显示帮助
```

## 安装后

服务通过 Docker Compose 管理：

```bash
docker compose logs -f   # 查看日志
docker compose down      # 停止所有服务
docker compose up -d     # 启动所有服务
docker compose ps        # 查看状态
```

访问地址：`http://localhost`（或你配置的域名）。

## 文档

- [高级配置](docs/advanced_cn.md) - 环境变量、性能优化、SSL 配置、故障排查
- [Advanced Configuration](docs/advanced.md) - English docs

## 国内加速

脚本自动使用 **Gitee 镜像** 加速 Git 克隆。

Docker 镜像加速（推荐）：
```bash
echo '{"registry-mirrors": ["https://docker.1ms.run"]}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

## 相关链接

- [Dify 官方](https://github.com/langgenius/dify) - 官方仓库
- [Dify 文档](https://docs.dify.ai) - 官方文档
- [Dify Cloud](https://cloud.dify.ai) - 托管服务

## 许可证

MIT
