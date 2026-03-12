# Advanced Configuration

This document covers advanced configuration options for the Dify one-click installer.

## Environment Variables

All configuration is stored in the `.env` file in your installation directory. Here are the key variables:

### Core Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `SECRET_KEY` | Application secret key | Auto-generated |
| `DB_TYPE` | Database type | `postgresql` |
| `DB_PASSWORD` | Database password | Auto-generated |
| `REDIS_PASSWORD` | Redis password | Auto-generated |
| `VECTOR_STORE` | Vector database | `weaviate` |

### Network Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `CONSOLE_API_URL` | Console API URL | `http://localhost` |
| `SERVICE_API_URL` | Service API URL | `http://localhost` |
| `NGINX_PORT` | HTTP port | `80` |
| `NGINX_SSL_PORT` | HTTPS port | `443` |

### Storage Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `STORAGE_TYPE` | Storage backend | `opendal` |
| `OPENDAL_SCHEME` | OpenDAL scheme | `fs` |
| `S3_BUCKET_NAME` | S3 bucket (if using S3) | - |
| `S3_REGION` | S3 region | - |

## Performance Tuning

### Database

For production workloads, consider:

1. **PostgreSQL**: Increase `shared_buffers` and `work_mem`
2. **MySQL**: Adjust `innodb_buffer_pool_size`

### Vector Database

- **Weaviate**: Best for most use cases
- **Qdrant**: Lightweight, good for development
- **Milvus**: Enterprise-grade, for large scale
- **pgvector**: Fewer services, uses existing PostgreSQL

### Redis

For high-traffic deployments, consider using a dedicated Redis instance.

## SSL Configuration

### Let's Encrypt (Certbot)

1. Ensure your domain points to the server
2. Open ports 80 and 443
3. Run: `docker compose --profile certbot up -d`

### Custom Certificates

1. Place certificates in `./nginx/ssl/`:
   - `dify.crt` - Certificate
   - `dify.key` - Private key
2. Set `NGINX_HTTPS_ENABLED=true` in `.env`

## Scaling

For horizontal scaling, consider:

1. Use external PostgreSQL/MySQL
2. Use external Redis
3. Use external vector database
4. Configure multiple API/Worker instances

## Backup

### Database Backup

```bash
# PostgreSQL
docker compose exec db pg_dump -U postgres dify > backup.sql

# MySQL
docker compose exec db mysqldump -u root -p dify > backup.sql
```

### Volume Backup

```bash
# Backup all volumes
docker compose down
tar -czvf dify-backup.tar.gz ./volumes
```

## Troubleshooting

### Port Conflicts

Check what's using a port:
```bash
lsof -i :80
```

### Container Issues

View container logs:
```bash
docker compose logs -f api
docker compose logs -f worker
```

### Reset Installation

```bash
docker compose down -v
rm .env
./install.sh
```

## More Resources

- [Dify Documentation](https://docs.dify.ai)
- [Dify GitHub](https://github.com/langgenius/dify)
- [Dify Cloud](https://cloud.dify.ai)
