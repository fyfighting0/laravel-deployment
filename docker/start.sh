#!/bin/bash
set -e

# 启动 PHP-FPM（后台运行）
php-fpm -D

# 启动 Nginx（前台运行，保持容器运行）
exec nginx -g "daemon off;"

