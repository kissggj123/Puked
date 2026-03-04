# Caddy 部署指南

## 概述

如果您已经在服务器上运行了 Caddy，可以直接将可乐杯物理模拟器添加到现有配置中。

## 方法一：添加到现有 Caddy 配置

### 1. 构建 Flutter Web 应用

```bash
# 在项目目录中
flutter build web --release

# 复制构建输出到 Caddy 网站目录
sudo cp -r build/web /var/www/cola-simulator
```

### 2. 修改 Caddyfile

编辑您的 Caddyfile，添加新的站点配置：

```caddyfile
# 现有配置...

# 添加可乐杯模拟器站点
cola.your-domain.com {
    root * /var/www/cola-simulator
    file_server
    try_files {path} {path}/ /index.html
    encode gzip zstd

    # 传感器 API 需要的权限策略
    header Permissions-Policy "accelerometer=(self), gyroscope=(self), magnetometer=(self)"

    # 安全响应头
    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
    }
}
```

### 3. 重载 Caddy 配置

```bash
sudo systemctl reload caddy
# 或
sudo caddy reload --config /etc/caddy/Caddyfile
```

## 方法二：使用子路径

如果您想将应用部署在现有域名的子路径下：

```caddyfile
your-domain.com {
    # 现有配置...

    # 可乐杯模拟器子路径
    handle_path /cola/* {
        root * /var/www/cola-simulator
        file_server
        try_files {path} {path}/ /index.html
        encode gzip zstd
        header Permissions-Policy "accelerometer=(self), gyroscope=(self), magnetometer=(self)"
    }
}
```

**注意**: 使用子路径时，需要修改 Flutter 的 base href：

```bash
flutter build web --release --base-href /cola/
```

## 方法三：反向代理到 Docker

如果您想用 Docker 运行应用，但使用 Caddy 作为入口：

### 1. 创建 docker-compose.yml

```yaml
version: '3.8'

services:
  cola-simulator:
    build: .
    container_name: cola-simulator
    restart: unless-stopped
    # 不暴露端口，通过 Caddy 反向代理
```

### 2. 修改 Caddyfile

```caddyfile
cola.your-domain.com {
    reverse_proxy localhost:8080

    # 传感器 API 需要的权限策略
    header Permissions-Policy "accelerometer=(self), gyroscope=(self), magnetometer=(self)"
}
```

### 3. 修改 Dockerfile 暴露端口

```dockerfile
# ... 其他配置
EXPOSE 8080
```

### 4. 启动服务

```bash
docker-compose up -d
sudo systemctl reload caddy
```

## 自动部署脚本

创建 `/usr/local/bin/deploy-cola.sh`：

```bash
#!/bin/bash

PROJECT_DIR="/path/to/cola-simulator"
WEB_ROOT="/var/www/cola-simulator"

cd $PROJECT_DIR

# 拉取最新代码
git pull

# 构建
flutter build web --release

# 部署
sudo rm -rf $WEB_ROOT/*
sudo cp -r build/web/* $WEB_ROOT/
sudo chown -R caddy:caddy $WEB_ROOT

# 重载 Caddy
sudo systemctl reload caddy

echo "部署完成: $(date)"
```

设置权限：

```bash
sudo chmod +x /usr/local/bin/deploy-cola.sh
```

## HTTPS 配置

Caddy 自动处理 HTTPS，只需确保域名指向服务器：

```caddyfile
cola.your-domain.com {
    # Caddy 自动获取 Let's Encrypt 证书
    root * /var/www/cola-simulator
    file_server
    try_files {path} {path}/ /index.html
    encode gzip zstd
    header Permissions-Policy "accelerometer=(self), gyroscope=(self), magnetometer=(self)"
}
```

## 故障排除

### 传感器权限问题

确保已添加 Permissions-Policy 响应头：

```bash
curl -I https://cola.your-domain.com
# 检查响应头中是否包含 Permissions-Policy
```

### 路由 404 错误

确保 try_files 配置正确：

```caddyfile
try_files {path} {path}/ /index.html
```

### 缓存问题

清除浏览器缓存或添加缓存控制：

```caddyfile
@static {
    path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg
}
header @static {
    Cache-Control "public, max-age=31536000, immutable"
}
```

## 监控

查看 Caddy 日志：

```bash
sudo journalctl -u caddy -f
```

查看访问日志：

```bash
sudo tail -f /var/log/caddy/access.log
```
