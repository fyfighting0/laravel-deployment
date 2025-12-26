# GitHub Actions Workflows

本目录包含 GitHub Actions 工作流配置文件。

## 工作流说明

### deploy.yml

**触发条件**:
- 推送到 `main` 分支
- 合并 PR 到 `main` 分支

**执行流程**:
1. 检出代码
2. 配置 AWS 凭证
3. 登录到 Amazon ECR
4. 构建 Docker 镜像（使用 `latest` 标签）
5. 推送镜像到 ECR
6. 强制更新 ECS Service 部署（`--force-new-deployment`）
7. 等待服务稳定
8. 通过 AWS SNS 发送通知（成功/失败）

**注意**: 
- 此工作流使用 `latest` 标签，Task Definition 中应配置 `latest` 标签的镜像
- 工作流会强制 ECS Service 重新部署，即使镜像标签相同也会拉取新镜像

**所需 Secrets**:
- `AWS_ACCESS_KEY_ID` - AWS 访问密钥 ID
- `AWS_SECRET_ACCESS_KEY` - AWS 密钥
- `SNS_TOPIC_ARN` - AWS SNS Topic ARN

详细配置请查看工作流文件中的注释说明。

