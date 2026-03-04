# Flutter Web 应用 Dockerfile
# 用于构建和部署可乐杯物理模拟器

# 构建阶段
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY pubspec.yaml pubspec.lock ./
COPY . .

# 获取依赖
RUN flutter pub get

# 构建 Web 应用
RUN flutter build web --release

# 生产阶段
FROM nginx:alpine

# 复制构建输出到 nginx 目录
COPY --from=builder /app/build/web /usr/share/nginx/html

# 复制 nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"]
