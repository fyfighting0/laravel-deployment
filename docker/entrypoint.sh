#!/bin/bash
set -e

# 等待数据库连接（如果需要）
if [ -n "$DB_HOST" ]; then
    echo "等待数据库连接..."
    until php -r "new PDO('pgsql:host=${DB_HOST};port=${DB_PORT:-5432};dbname=${DB_DATABASE}', '${DB_USERNAME}', '${DB_PASSWORD}');" 2>/dev/null; do
        echo "数据库未就绪，等待中..."
        sleep 2
    done
    echo "数据库连接成功！"
fi

# 安装 Composer 依赖（如果 vendor 目录不存在）
if [ ! -d "vendor" ]; then
    echo "安装 Composer 依赖..."
    composer install --no-dev --optimize-autoloader
fi

# 生成应用密钥（如果不存在）
if [ ! -f ".env" ]; then
    echo "创建 .env 文件..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
    else
        # 如果 .env.example 不存在，创建基本的 .env 文件
        cat > .env << 'EOF'
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_TIMEZONE=UTC
APP_URL=http://localhost

LOG_CHANNEL=cloudwatch
LOG_LEVEL=debug

SESSION_DRIVER=file
SESSION_LIFETIME=120

DB_CONNECTION=pgsql
EOF
    fi
fi

# 检查并生成 APP_KEY（如果不存在或为空）
# 注意：需要先安装依赖才能运行 artisan 命令
if [ -d "vendor" ] && [ -f ".env" ]; then
    # 检查 .env 文件中是否有有效的 APP_KEY（格式：APP_KEY=base64:...）
    if ! grep -q "^APP_KEY=base64:" .env 2>/dev/null; then
        echo "生成应用加密密钥..."
        # 清除可能存在的配置缓存
        rm -f bootstrap/cache/config.php 2>/dev/null || true
        
        # 确保 .env 文件中有 APP_KEY= 行（artisan key:generate 需要这一行存在）
        if ! grep -q "^APP_KEY=" .env 2>/dev/null; then
            echo "APP_KEY=" >> .env
        else
            # 如果存在但格式不对，替换为空行
            sed -i 's|^APP_KEY=.*|APP_KEY=|' .env 2>/dev/null || true
        fi
        
        # 生成新的 APP_KEY
        # 首先尝试使用 artisan 命令
        if php artisan key:generate --force --show 2>&1 | grep -q "base64:"; then
            echo "使用 artisan 命令生成密钥成功"
        else
            echo "警告: artisan key:generate 失败，使用 PHP 直接生成..."
            # 如果 artisan 命令失败，使用 PHP 直接生成
            NEW_KEY=$(php -r "echo 'base64:' . base64_encode(random_bytes(32));")
            # 替换 APP_KEY 行
            sed -i "s|^APP_KEY=.*|APP_KEY=$NEW_KEY|" .env
            echo "使用 PHP 直接生成密钥成功"
        fi
        
        # 验证 APP_KEY 是否已生成
        if grep -q "^APP_KEY=base64:" .env 2>/dev/null; then
            APP_KEY_VALUE=$(grep "^APP_KEY=" .env | cut -d '=' -f2)
            echo "应用加密密钥已成功生成: ${APP_KEY_VALUE:0:20}..."
        else
            echo "错误: 无法生成应用加密密钥，尝试手动生成..."
            # 最后的后备方案：直接写入
            NEW_KEY=$(php -r "echo 'base64:' . base64_encode(random_bytes(32));")
            sed -i "s|^APP_KEY=.*|APP_KEY=$NEW_KEY|" .env
            echo "手动生成密钥完成"
        fi
    else
        echo "应用加密密钥已存在"
    fi
fi

# 清除旧的配置缓存（确保使用最新的 .env 配置）
rm -f bootstrap/cache/config.php 2>/dev/null || true

# 运行 Laravel 优化命令
php artisan config:cache || true
php artisan route:cache || true
# 只有在 views 目录存在时才缓存视图
if [ -d "resources/views" ]; then
    php artisan view:cache || true
fi

# 执行传入的命令
exec "$@"

