# 使用 PHP 8.4 FPM 作为基础镜像
FROM php:8.4-fpm

# 设置工作目录
WORKDIR /var/www/html

# 安装系统依赖和 Nginx
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
    zip \
    unzip \
    awscli \
    nginx \
    && docker-php-ext-install pdo pdo_pgsql mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 复制应用文件
COPY . /var/www/html

# 设置权限
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# 复制 PHP-FPM 配置
COPY docker/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY docker/php.ini /usr/local/etc/php/conf.d/custom.ini

# 复制 Nginx 配置
COPY docker/nginx-main.conf /etc/nginx/nginx.conf
COPY docker/nginx.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# 复制启动脚本
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/start.sh

# 暴露端口（Nginx 使用 80 端口）
EXPOSE 80

# 启动 PHP-FPM 和 Nginx
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/start.sh"]

