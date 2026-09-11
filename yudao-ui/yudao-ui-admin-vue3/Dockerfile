FROM nginx:alpine

# 替换 nginx 配置文件以支持 vue-router 的 history 模式
COPY nginx.conf /etc/nginx/nginx.conf

# 将本地打包生成的 dist 文件夹内容复制到 nginx 的默认站点目录下
COPY dist/ /usr/share/nginx/html/

# 暴露 80 端口
EXPOSE 80

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]
