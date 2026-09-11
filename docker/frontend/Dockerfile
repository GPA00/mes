FROM nginx:alpine

LABEL maintainer="MES Team"
LABEL description="MES Frontend Web Container"

# 替换 Nginx 核心配置文件以支持 Vue Router History 模式及后端代理
COPY nginx.conf /etc/nginx/nginx.conf

# 拷贝前端打包生成的 dist 静态目录至 Nginx 站点根路径
COPY dist/ /usr/share/nginx/html/

# 暴露容器内 80 端口 (宿主机对外映射端口通过 docker-compose 配置为 1228)
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]