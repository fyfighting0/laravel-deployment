# Laravel 11 (PHP 8.4) ECS Fargate 部署项目

这个项目用于构建和部署一个符合 AWS ECS Fargate 部署要求的 Laravel 11 (PHP 8.4) Docker 镜像。

## 项目概述

这是一个完整的 Laravel 11 应用 Docker 镜像构建项目，专为 AWS ECS Fargate 部署设计。

## 功能特性

1. **Laravel 11 应用** - 基于 PHP 8.4 FPM + Nginx
2. **环境变量显示** - 首页显示特定的环境变量
3. **JSON 格式访问日志** - 包含 X-Amzn-Trace-Id，输出到 CloudWatch
4. **PHP/PHP-FPM 日志** - 所有日志收集到 CloudWatch
5. **PostgreSQL 支持** - 与 RDS (PostgreSQL) 实例关联
6. **CloudWatch 集成** - 所有日志自动收集到 CloudWatch Logs
7. **CI/CD 自动化** - GitHub Actions 自动构建、推送和部署，通过 AWS SNS 发送通知

## 快速开始

### 构建镜像

```bash
docker build -t laravel-11-php84:latest .
```

### 本地测试

```bash
docker run -p 8080:80 \
  -e DB_HOST=your-rds-endpoint \
  -e DB_DATABASE=postgres \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=your-password \
  -e DISPLAY_ENV_VAR=MyApp \
  -e DB_CONNECTION=pgsql \
  -e DB_PORT=5432 \
  laravel-11-php84:latest
```

然后在浏览器中访问：**http://localhost:8080**

### CI/CD 自动部署

当代码推送到 `main` 分支或合并 PR 时，GitHub Actions 会自动：

1. 构建 Docker 镜像（使用 `latest` 标签）
2. 推送到 Amazon ECR
3. 强制更新 ECS Service 部署
4. 通过 AWS SNS 发送部署通知（成功/失败）

**配置说明**：
- 工作流文件：`.github/workflows/deploy.yml`
- 需要配置 GitHub Secrets：`AWS_ACCESS_KEY_ID`、`AWS_SECRET_ACCESS_KEY`、`SNS_TOPIC_ARN`
- Task Definition 中应配置使用 `latest` 标签的镜像

## CI/CD 配置

### GitHub Actions 工作流

工作流文件位于 `.github/workflows/deploy.yml`，实现自动构建和部署。

**触发条件**：
- 推送到 `main` 分支
- 合并 PR 到 `main` 分支

**部署流程**：
1. 构建 Docker 镜像（`latest` 标签）
2. 推送到 Amazon ECR
3. 强制更新 ECS Service（`--force-new-deployment`）
4. 等待服务稳定
5. 发送 SNS 通知（成功/失败）

**需要配置的参数**（在 `.github/workflows/deploy.yml` 中）：
- `AWS_REGION` - AWS 区域
- `ECR_REPOSITORY` - ECR 仓库名称
- `ECS_SERVICE` - ECS 服务名称
- `ECS_CLUSTER` - ECS 集群名称

**需要配置的 GitHub Secrets**：
- `AWS_ACCESS_KEY_ID` - AWS 访问密钥 ID
- `AWS_SECRET_ACCESS_KEY` - AWS 密钥
- `SNS_TOPIC_ARN` - SNS Topic ARN（用于通知）


## 技术栈

- **PHP**: 8.4 FPM
- **Web 服务器**: Nginx
- **框架**: Laravel 11
- **数据库**: PostgreSQL (RDS)
- **容器平台**: Docker
- **部署平台**: AWS ECS Fargate
- **日志**: CloudWatch Logs

## 镜像特点

- PHP 8.4 FPM + Nginx 集成
- 所有日志输出到 stderr/stdout（CloudWatch 自动收集）
- JSON 格式日志，包含 X-Amzn-Trace-Id
- PostgreSQL 支持（RDS 就绪）
- OPcache 和 Laravel 优化配置
- 自动生成 APP_KEY
- 数据库连接自动检测

## 环境变量

### 必需变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `DB_HOST` | RDS 端点地址 | `your-db.region.rds.amazonaws.com` |
| `DB_DATABASE` | 数据库名称 | `postgres` |
| `DB_USERNAME` | 数据库用户名 | `postgres` |
| `DB_PASSWORD` | 数据库密码 | `your-password` |
| `DB_CONNECTION` | 数据库类型 | `pgsql` |
| `DB_PORT` | 数据库端口 | `5432` |

### 可选变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `DISPLAY_ENV_VAR` | 首页显示的环境变量 | `APP_NAME` |
| `APP_NAME` | 应用名称 | `Laravel` |
| `APP_ENV` | 应用环境 | `production` |
| `APP_DEBUG` | 调试模式 | `false` |
| `SESSION_DRIVER` | 会话驱动 | `file` |

## 日志说明

所有日志都输出到 **stderr/stdout**，由 CloudWatch Logs Agent 自动收集：

- **PHP 错误日志** - 输出到 stderr
- **PHP-FPM 访问日志** - 输出到 stderr（包含 X-Amzn-Trace-Id）
- **PHP-FPM 错误日志** - 输出到 stderr
- **Laravel 应用日志** - JSON 格式输出到 stderr
- **Nginx 访问日志** - JSON 格式输出到 stderr（包含 X-Amzn-Trace-Id）

所有日志通过 CloudWatch Logs Agent 自动收集，无需额外配置。

## 项目结构

```
.
├── app/                    # Laravel 应用代码
│   └── Http/
│       └── Middleware/     # 请求日志中间件
├── config/                 # Laravel 配置文件
├── docker/                 # Docker 相关配置
│   ├── entrypoint.sh      # 容器启动脚本
│   ├── start.sh           # 服务启动脚本
│   ├── nginx.conf         # Nginx 站点配置
│   ├── nginx-main.conf    # Nginx 主配置
│   ├── php-fpm.conf       # PHP-FPM 配置
│   └── php.ini            # PHP 配置
├── .github/                 # GitHub Actions 工作流配置
│   └── workflows/
│       └── deploy.yml       # CI/CD 部署工作流
├── public/                 # Web 入口
├── routes/                 # 路由定义
├── storage/                # 存储目录
├── Dockerfile              # Docker 镜像定义
└── README.md              # 项目说明

```


## 相关链接

- [Laravel 官方文档](https://laravel.com/docs)
- [AWS ECS 文档](https://docs.aws.amazon.com/ecs/)
- [AWS RDS 文档](https://docs.aws.amazon.com/rds/)

## 许可证

MIT License

