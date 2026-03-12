# 高级配置

本文档介绍 Dify 安装器的高级配置选项。

## 环境变量

配置存储在安装目录的 `.env` 文件中。

### 核心配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `SECRET_KEY` | 应用密钥 | 自动生成 |
| `DB_TYPE` | 数据库类型 | `postgresql` |
| `DB_PASSWORD` | 数据库密码 | 自动生成 |
| `REDIS_PASSWORD` | Redis 密码 | 自动生成 |
| `VECTOR_STORE` | 向量数据库 | `weaviate` |

### 网络配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `CONSOLE_API_URL` | 控制台 API 地址 | `http://localhost` |
| `NGINX_PORT` | HTTP 端口 | `80` |
| `NGINX_SSL_PORT` | HTTPS 端口 | `443` |

### 存储配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `STORAGE_TYPE` | 存储类型 | `opendal` |
| `S3_BUCKET_NAME` | S3 存储桶 | - |

## 性能优化

### 数据库

生产环境建议：
- **PostgreSQL**: 调整 `shared_buffers` 和 `work_mem`
- **MySQL**: 调整 `innodb_buffer_pool_size`

### 向量数据库选择

| 数据库 | 特点 |
|--------|------|
| Weaviate | 推荐，稳定可靠 |
| Qdrant | 轻量快速 |
| Milvus | 企业级，大规模 |
| pgvector | 复用 PostgreSQL，服务少 |

## SSL 配置

### Let's Encrypt

1. 确保域名解析到服务器
2. 开放 80、443 端口
3. 运行：`docker compose --profile certbot up -d`

### 自定义证书

1. 证书放在 `./nginx/ssl/`：
   - `dify.crt` - 证书
   - `dify.key` - 私钥
2. 设置 `NGINX_HTTPS_ENABLED=true`

## 备份

### 数据库备份

```bash
# PostgreSQL
docker compose exec db pg_dump -U postgres dify > backup.sql

# MySQL
docker compose exec db mysqldump -u root -p dify > backup.sql
```

### 完整备份

```bash
docker compose down
tar -czvf dify-backup.tar.gz ./
```

## 故障排除

### 端口冲突

```bash
lsof -i :80  # 查看端口占用
```

### 容器问题

```bash
docker compose logs -f api     # API 日志
docker compose logs -f worker  # Worker 日志
```

### 重置安装

```bash
docker compose down -v
rm .env
./install_cn.sh
```

## 更多资源

- [Dify 文档](https://docs.dify.ai)
- [Dify GitHub](https://github.com/langgenius/dify)
