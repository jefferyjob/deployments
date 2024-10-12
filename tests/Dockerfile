FROM registry.cn-hangzhou.aliyuncs.com/jefferyjob/nginx:latest

WORKDIR /usr/share/nginx/html
RUN echo '<!DOCTYPE html><html><head><title>Hello Jefferyjob</title></head><body><h1>Hello Jefferyjob/deployments</h1></body></html>' > index.html
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
