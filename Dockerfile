ARG NGINX_VERSION=1.22.0
ARG BITNAMI_NGINX_REVISION=r3
ARG BITNAMI_NGINX_TAG=${NGINX_VERSION}-debian-11-${BITNAMI_NGINX_REVISION}

FROM bitnami/nginx:${BITNAMI_NGINX_TAG} AS builder
USER root
## Redeclare NGINX_VERSION so it can be used as a parameter inside this build stage
ARG NGINX_VERSION
## Install required packages and build dependencies
RUN install_packages dirmngr gpg gpg-agent curl build-essential libpcre3-dev zlib1g-dev libssl-dev

## Add trusted NGINX PGP key for tarball integrity verification
# server was down : RUN gpg --keyserver pgp.mit.edu --recv-key 13C82A63B603576156E30A4EA0EA981B66B0D967
RUN curl -sSL https://nginx.org/keys/thresh.key | gpg --import -
RUN curl -sSL https://nginx.org/keys/nginx_signing.key | gpg --import -
### 

## Download NGINX, verify integrity and extract
RUN cd /tmp && \
    curl -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    curl -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc && \
    gpg --verify nginx-${NGINX_VERSION}.tar.gz.asc nginx-${NGINX_VERSION}.tar.gz && \
    tar xzf nginx-${NGINX_VERSION}.tar.gz
## Compile NGINX with desired module
RUN cd /tmp/nginx-${NGINX_VERSION} && \
    rm -rf /opt/bitnami/nginx && \
    ./configure --prefix=/opt/bitnami/nginx --with-http_stub_status_module --with-stream --with-http_gzip_static_module --with-mail \
                --with-http_realip_module --with-http_stub_status_module --with-http_v2_module --with-http_ssl_module --with-mail_ssl_module \
                --with-http_gunzip_module --with-threads --with-http_auth_request_module --with-http_sub_module \
                --with-compat --with-stream_realip_module --with-stream_ssl_module && \
    make && \
    make install

RUN ls -la /opt/bitnami/nginx/

FROM bitnami/nginx:${BITNAMI_NGINX_TAG}
USER root
## Install ngx_stream_ssl_module files
COPY --from=builder /opt/bitnami/nginx/sbin /opt/bitnami/nginx/sbin
## Set the container to be run as a non-root user by default
USER 1001
