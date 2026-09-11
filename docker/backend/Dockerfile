FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="MES Team"
LABEL description="MES Backend Yudao-Server Container"

# 安装时区支持与开源基础字体库（避免图形验证码、EasyExcel导出报表、打印条码时因缺少字体抛出 NullPointerException）
RUN apk add --no-cache tzdata fontconfig ttf-dejavu && \
    ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

WORKDIR /app

# 复制宿主机通过 Maven 编译出的 yudao-server.jar
COPY yudao-server.jar app.jar

# 声明容器对外暴露的后端端口
EXPOSE 48080

# 启动命令：支持通过环境变量动态注入 JAVA_OPTS 堆内存与垃圾回收器调优参数
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar"]