# Dify 一键安装脚本

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/caoergou/dify-installer.svg)](https://github.com/caoergou/dify-installer/stargazers)

[Dify](https://github.com/langgenius/dify) Docker 部署的一键安装脚本。只需一行命令，几分钟内即可完成 Dify 的部署。

## 功能特性

- **一行命令安装** - 只需 curl 和 bash
- **自动浅克隆** - 仅下载必要文件
- **交互式配置** - 智能默认值，引导式设置
- **数据库选择** - PostgreSQL 或 MySQL
- **向量数据库选择** - Weaviate、Qdrant、Milvus、Chroma 或 pgvector
- **存储选项** - 本地、S3、Azure、GCS 或阿里云 OSS
- **SSL 支持** - Let's Encrypt 或自定义证书
- **邮件配置** - SMTP、Gmail、SendGrid 或 Resend

## 快速开始

### 标准版（全球用户）

```bash
curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install.sh | bash
```

### 中国优化版（推荐国内用户使用）

使用 Gitee 镜像加速下载：

```bash
curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install_cn.sh | bash
```

就是这么简单！安装脚本会引导你完成其余配置。

### 非交互模式

适用于自动化部署，使用 `--yes` 参数：

```bash
curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install_cn.sh | bash -s -- --yes
```

## 系统要求

- 已安装 **Docker** 和 **Docker Compose**
- 推荐 **2+ CPU 核心**
- 推荐 **4GB+ 内存**
- 可用端口 **80、443**（可配置）

## Docker 镜像加速配置

在国内拉取 Docker 镜像可能较慢，建议配置镜像加速器：

### Linux 配置方法

1. 编辑 `/etc/docker/daemon.json`（如不存在请创建）：

```json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me"
  ]
}
```

2. 重启 Docker 服务：

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Docker Desktop (macOS/Windows)

在 Docker Desktop 设置 -> Docker Engine 中添加上述配置。

## 使用方法

### 交互模式（推荐）

运行安装脚本并按提示操作：

```bash
./install_cn.sh
```

### 非交互模式

使用所有推荐的默认值，无需交互：

```bash
./install_cn.sh --yes
# 或
./install_cn.sh -y
```

### 显示帮助

```bash
./install_cn.sh --help
```

## 配置选项

安装脚本会询问以下配置：

| 选项 | 描述 | 默认值 |
|------|------|--------|
| 部署类型 | 私有（本地）或 公开（域名） | 私有 |
| HTTP 端口 | Web 访问端口 | 80 |
| 数据库 | PostgreSQL 或 MySQL | PostgreSQL |
| 向量数据库 | Weaviate、Qdrant、Milvus、Chroma、pgvector | Weaviate |
| 存储 | 本地、S3、Azure、GCS、阿里云 OSS | 本地 |
| 邮件 | SMTP 配置（可选） | 未配置 |

所有密钥都会自动安全生成。

## 安装后

安装完成后，Dify 将在 `http://localhost`（或你配置的域名）上可用。

### 常用命令

在安装目录下运行：

```bash
# 查看日志
docker compose logs -f

# 停止服务
docker compose down

# 启动服务
docker compose up -d

# 查看状态
docker compose ps
```

## 安装内容

安装脚本会克隆官方 [Dify 仓库](https://github.com/langgenius/dify) 并设置：

- **API** - 后端服务
- **Web** - 前端应用
- **Worker** - 后台任务处理器
- **Nginx** - 反向代理
- **Database** - PostgreSQL 或 MySQL
- **Redis** - 缓存和消息队列
- **Vector DB** - 你选择的 Weaviate、Qdrant、Milvus、Chroma 或 pgvector

## 安全特性

- **RCE 防护** - 验证 git 仓库真实性
- **安全密钥** - 使用加密安全的随机生成
- **文件权限** - 为 `.env` 文件设置限制权限
- **目录安全** - 操作前检查所有权

## 镜像源说明

### Git 仓库镜像

中国优化版脚本优先使用 Gitee 镜像：
- 主镜像：`https://gitee.com/fast-mirrors/dify.git`
- 备用：`https://github.com/langgenius/dify.git`

### Docker 镜像

建议配置 Docker 镜像加速器以加快镜像拉取速度。

## 相关链接

- [Dify 官方仓库](https://github.com/langgenius/dify)
- [Gitee 镜像仓库](https://gitee.com/fast-mirrors/dify)
- [Dify 文档](https://docs.dify.ai)
- [Dify Cloud](https://cloud.dify.ai) - 托管服务

## 贡献

欢迎提交 Pull Request 参与贡献！

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 致谢

- [Dify 团队](https://github.com/langgenius) 创建了优秀的 LLM 应用平台
- 所有帮助改进此安装脚本贡献者

---

**注意**：这是一个独立的社区项目。如需官方 Dify 支持，请访问[官方仓库](https://github.com/langgenius/dify)。
