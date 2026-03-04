# 可乐杯物理模拟器 - 部署指南

## 概述

本文档介绍如何在 Debian 服务器上部署可乐杯物理模拟器 Web 应用。

## 系统要求

- Debian 11+ 或 Ubuntu 20.04+
- Docker 20.10+
- Docker Compose 1.29+
- 至少 2GB RAM
- 至少 10GB 磁盘空间

## 快速部署

### 1. 安装 Docker 和 Docker Compose

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Docker
sudo apt install -y docker.io docker-compose

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 将当前用户添加到 docker 组
sudo usermod -aG docker $USER
```

### 2. 克隆项目

```bash
git clone <your-repo-url> cola-simulator
cd cola-simulator
```

### 3. 使用 Docker Compose 部署

```bash
# 构建并启动服务
docker-compose up -d --build

# 查看日志
docker-compose logs -f
```

应用将在 http://localhost:8080 上运行。

## 手动部署 (不使用 Docker)

### 1. 安装 Flutter SDK

```bash
# 下载 Flutter
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
tar xf flutter_linux_3.24.0-stable.tar.xz
sudo mv flutter /opt/

# 添加到 PATH
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# 验证安装
flutter doctor
```

### 2. 启用 Web 支持

```bash
flutter config --enable-web
```

### 3. 构建 Web 应用

```bash
cd cola-simulator
flutter pub get
flutter build web --release
```

### 4. 配置 Nginx

```bash
# 安装 Nginx
sudo apt install -y nginx

# 复制构建输出
sudo cp -r build/web/* /var/www/html/

# 复制 Nginx 配置
sudo cp nginx.conf /etc/nginx/sites-available/cola-simulator
sudo ln -s /etc/nginx/sites-available/cola-simulator /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

## HTTPS 配置 (推荐)

传感器 API 需要 HTTPS 才能在移动设备上正常工作。

### 使用 Let's Encrypt

```bash
# 安装 Certbot
sudo apt install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo systemctl enable certbot.timer
```

### 手动配置 HTTPS

```bash
# 生成自签名证书 (仅用于测试)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx.key \
  -out /etc/nginx/ssl/nginx.crt

# 修改 nginx.conf 启用 HTTPS
```

## 系统服务配置

创建 systemd 服务文件 `/etc/systemd/system/cola-simulator.service`:

```ini
[Unit]
Description=Cola Simulator Web App
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/path/to/cola-simulator
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down

[Install]
WantedBy=multi-user.target
```

启用服务:

```bash
sudo systemctl daemon-reload
sudo systemctl enable cola-simulator
sudo systemctl start cola-simulator
```

## 更新应用

```bash
cd cola-simulator
git pull

# 重新构建并部署
docker-compose down
docker-compose up -d --build
```

## 监控和日志

```bash
# 查看容器状态
docker-compose ps

# 查看应用日志
docker-compose logs -f cola-simulator

# 查看 Nginx 访问日志
docker-compose exec cola-simulator tail -f /var/log/nginx/access.log

# 查看资源使用
docker stats
```

## 故障排除

### 传感器权限问题

确保使用 HTTPS 访问应用。传感器 API 在非安全上下文中不可用。

### 构建失败

```bash
# 清理并重新构建
docker-compose down -v
docker system prune -a
docker-compose up -d --build
```

### 端口冲突

如果 8080 端口被占用，修改 `docker-compose.yml`:

```yaml
ports:
  - "8081:80"  # 使用其他端口
```

## 性能优化

### Nginx 优化

已在 `nginx.conf` 中配置:
- Gzip 压缩
- 静态资源缓存
- 安全响应头

### Flutter 优化

构建时已启用:
- Tree shaking
- Minification
- 资源压缩

## 安全建议

1. 始终使用 HTTPS 生产环境
2. 定期更新 Docker 镜像
3. 配置防火墙规则
4. 启用自动安全更新

```bash
# 配置 UFW 防火墙
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## 浏览器兼容性

- Chrome 90+
- Edge 90+
- Safari 14+ (iOS 14+)
- Firefox 88+

## 移动端优化

应用已针对移动设备进行优化:
- 响应式布局
- 触摸友好的控件
- 传感器权限处理
- PWA 支持

## 支持

如有问题，请查看项目文档或提交 Issue。
