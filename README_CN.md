# Dify 安装器

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**一行命令部署 Dify。** 无需复杂配置，无需手动克隆。

```bash
curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install_cn.sh | bash
```

## 什么是 Dify？

[Dify](https://github.com/langgenius/dify) 是开源的 LLM 应用开发平台。本安装器让你几分钟内完成部署。

## 一键安装

| 地区 | 命令 |
|------|------|
| 国内 | `curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install_cn.sh \| bash` |
| 海外 | `curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install.sh \| bash` |

## 功能特性

- 交互式配置，智能默认值
- PostgreSQL 或 MySQL
- 向量数据库：Weaviate、Qdrant、Milvus、Chroma、pgvector
- 存储：本地、S3、Azure、GCS、阿里云 OSS
- SSL 证书：Let's Encrypt 或自定义

## 系统要求

- Docker + Docker Compose
- 2+ CPU 核心，4GB+ 内存
- 端口 80、443 可用

## 常用命令

```bash
./install_cn.sh           # 交互式配置
./install_cn.sh --yes     # 使用默认值
./install_cn.sh --help    # 显示帮助
```

安装后：
```bash
docker compose logs -f   # 查看日志
docker compose down      # 停止服务
docker compose up -d     # 启动服务
```

## 国内加速

脚本自动使用 **Gitee 镜像** 加速下载。

Docker 镜像加速（推荐配置）：
```bash
# 编辑 /etc/docker/daemon.json
echo '{"registry-mirrors": ["https://docker.1ms.run"]}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

## 相关链接

- [Dify 官方](https://github.com/langgenius/dify) - 官方仓库
- [文档](https://docs.dify.ai) - 官方文档
- [云服务](https://cloud.dify.ai) - 托管服务

## 许可证

MIT
