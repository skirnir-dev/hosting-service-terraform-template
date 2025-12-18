# Terraform Cloud から Azure Storage Backend への移行手順

既存の Terraform Cloud を使用しているプロジェクトを Azure Storage Backend + GitHub Actions に移行する手順です。

## 前提条件

- 既存の Terraform Cloud ワークスペースで管理されているプロジェクト
- Azure CLI (`az`) がインストール済み
- 1Password CLI (`op`) がインストール済み
- GitHub CLI (`gh`) がインストール済み

## 移行概要

```
移行フロー:
1. Terraform Cloud → state backup
2. Service Principal 手動作成
3. 1Password 設定
4. GitHub Environment 設定
5. Terraform 設定更新
6. local backend で初期化 + github_actions モジュール作成
7. Azure Storage Backend へ移行
8. GitHub Actions 検証
9. Terraform Cloud 削除
```

## Phase 1: 事前準備

### 1-1. Terraform Cloud から state をバックアップ

```bash
# 現在のディレクトリで実行
terraform state pull > terraform.tfstate.tfcloud.backup
```

### 1-2. 現在のリソース数を確認

```bash
terraform state list | wc -l
# 例: 89
```

## Phase 2: Service Principal 手動作成（Bootstrap）

Storage Account を作成するために、先に Service Principal を手動で作成します。

```bash
# プロジェクト名を設定
PROJECT_NAME="<project>"

# 1. Azure AD Application 作成
az ad app create --display-name "${PROJECT_NAME}-terraform"
APP_ID=$(az ad app list --display-name "${PROJECT_NAME}-terraform" --query "[0].appId" -o tsv)
OBJECT_ID=$(az ad app list --display-name "${PROJECT_NAME}-terraform" --query "[0].id" -o tsv)

# 2. Service Principal 作成
az ad sp create --id $APP_ID
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query "id" -o tsv)

# 3. Federated Credential 追加
az ad app federated-credential create \
  --id $OBJECT_ID \
  --parameters "{
    \"name\": \"${PROJECT_NAME}-github-actions\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:skirnir-dev/${PROJECT_NAME}-terraform:environment:production\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# 4. Contributor 権限付与
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID

# 5. 値を記録
echo "=========================================="
echo "AZURE_CLIENT_ID: $APP_ID"
echo "APP_OBJECT_ID: $OBJECT_ID"
echo "SP_OBJECT_ID: $SP_OBJECT_ID"
echo "=========================================="
```

## Phase 3: 1Password 設定

### 3-1. プロジェクト専用 Vault 作成

```bash
op vault create ${PROJECT_NAME}-infrastructure
```

### 3-2. Azure 認証情報アイテム作成

```bash
op item create --category="API Credential" --title="azure-credentials" \
  --vault="${PROJECT_NAME}-infrastructure" \
  "AZURE_CLIENT_ID=$APP_ID"
```

### 3-3. Terraform secrets アイテム作成

既存の Terraform Cloud 変数から値を取得して設定:

```bash
# Terraform Cloud の変数を確認
# Web UI: https://app.terraform.io/app/skirnir/<workspace>/variables

op item create --category="API Credential" --title="terraform-secrets" \
  --vault="${PROJECT_NAME}-infrastructure" \
  "cloudflare_api_token=<既存の値>" \
  "sendgrid_api_key=<既存の値>" \
  "mackerel_api_key=<既存の値>"
```

### 3-4. Service Account 作成

```bash
op service-account create "github-actions-${PROJECT_NAME}" \
  --vault "skirnir-workload-identity:read_items" \
  --vault "${PROJECT_NAME}-infrastructure:read_items"

# 表示されたトークンを安全に保存（一度だけ表示される）
```

## Phase 4: GitHub Environment 設定

```bash
# Environment 作成
gh api repos/skirnir-dev/${PROJECT_NAME}-terraform/environments/production --method PUT

# Secret 設定
gh secret set OP_SERVICE_ACCOUNT_TOKEN \
  --repo skirnir-dev/${PROJECT_NAME}-terraform \
  --env production
# プロンプトで Service Account トークンを入力
```

## Phase 5: Terraform 設定更新

### 5-1. providers.tf の更新

Terraform Cloud backend をコメントアウトし、Azure Storage backend を準備:

```hcl
terraform {
  # Terraform Cloud (コメントアウト)
  # cloud {
  #   organization = "skirnir"
  #   workspaces {
  #     name = "<workspace>"
  #   }
  # }

  # Azure Storage Backend (Bootstrap後にコメント解除)
  # backend "azurerm" {
  #   resource_group_name  = "<fqdn>"
  #   storage_account_name = "state<project>"
  #   container_name       = "tfstate"
  #   key                  = "<project>-terraform.tfstate"
  # }

  required_version = ">=1.7"

  required_providers {
    # ... 既存のプロバイダー ...
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.47"
    }
  }
}

provider "azuread" {}
```

### 5-2. variables.tf に project_name 追加

```hcl
variable "project_name" {
  description = "Project name for CI/CD resources"
  type        = string
  default     = "<project>"
}
```

### 5-3. main.tf に github_actions モジュール追加

```hcl
module "github_actions" {
  source         = "./modules/github_actions"
  project_name   = var.project_name
  resource_group = azurerm_resource_group.rg
}

output "azure_client_id" {
  value       = module.github_actions.azure_client_id
  description = "Azure AD Application (Client) ID - Save to 1Password"
  sensitive   = true
}

output "storage_account_name" {
  value       = module.github_actions.storage_account_name
  description = "Storage Account name for providers.tf backend configuration"
}
```

### 5-4. modules/github_actions をコピー

テンプレートから `modules/github_actions` ディレクトリをコピー:

```bash
cp -r ../hosting-service-terraform-template/modules/github_actions ./modules/
```

### 5-5. .github/workflows/terraform.yml をコピー

```bash
mkdir -p .github/workflows
cp ../hosting-service-terraform-template/.github/workflows/terraform.yml .github/workflows/

# <project> を実際のプロジェクト名に置換
# Linux の場合:
sed -i "s/<project>/${PROJECT_NAME}/g" .github/workflows/terraform.yml
# macOS の場合:
# sed -i '' "s/<project>/${PROJECT_NAME}/g" .github/workflows/terraform.yml
# または、両環境で動作する perl を使用:
# perl -pi -e "s/<project>/${PROJECT_NAME}/g" .github/workflows/terraform.yml
```

## Phase 6: Bootstrap 実行

### 6-1. Terraform Cloud state を復元

```bash
# Terraform Cloud backend をコメントアウトした状態で
terraform init

# バックアップした state を復元
cp terraform.tfstate.tfcloud.backup terraform.tfstate
```

### 6-2. github_actions モジュールを作成

```bash
terraform apply -target=module.github_actions
```

### 6-3. Import ブロックを作成（Phase 2 で作成したリソース用）

`imports.tf` を作成:

```hcl
import {
  to = module.github_actions.azuread_application.terraform
  id = "/applications/<APP_OBJECT_ID>"
}

import {
  to = module.github_actions.azuread_service_principal.terraform
  id = "<SP_OBJECT_ID>"
}

import {
  to = module.github_actions.azuread_application_federated_identity_credential.github_actions
  id = "<APP_OBJECT_ID>/federatedIdentityCredential/<CREDENTIAL_ID>"
}

import {
  to = module.github_actions.azurerm_role_assignment.terraform_contributor
  id = "/subscriptions/<SUBSCRIPTION_ID>/providers/Microsoft.Authorization/roleAssignments/<ROLE_ASSIGNMENT_ID>"
}
```

> **Note**: ID の取得方法:
> - APP_OBJECT_ID: `az ad app list --display-name "${PROJECT_NAME}-terraform" --query "[0].id" -o tsv`
> - CREDENTIAL_ID: `az ad app federated-credential list --id $OBJECT_ID --query "[0].id" -o tsv`
> - ROLE_ASSIGNMENT_ID: `az role assignment list --assignee $SP_OBJECT_ID --query "[?roleDefinitionName=='Contributor'].id" -o tsv`

### 6-4. Plan でインポートを確認

```bash
terraform plan
```

### 6-5. Apply でインポート実行

```bash
terraform apply
```

### 6-6. local state をバックアップ

```bash
cp terraform.tfstate terraform.tfstate.local.backup
```

## Phase 7: Azure Storage Backend へ移行

### 7-1. providers.tf の backend ブロックをコメント解除

```hcl
backend "azurerm" {
  resource_group_name  = "<fqdn>"
  storage_account_name = "state<project>"
  container_name       = "tfstate"
  key                  = "<project>-terraform.tfstate"
}
```

### 7-2. Backend 移行

```bash
terraform init -migrate-state
```

確認メッセージに `yes` と入力。

### 7-3. State 確認

```bash
terraform state list | wc -l
# Phase 1 と同じ数 + github_actions モジュールのリソース数

terraform plan
# No changes が理想
```

## Phase 8: GitHub Actions 検証

### 8-1. ブランチ作成とコミット

```bash
git checkout -b migrate/terraform-cloud-to-azure-storage
git add .
git commit -m "feat: migrate from Terraform Cloud to Azure Storage + GitHub Actions"
git push -u origin migrate/terraform-cloud-to-azure-storage
```

### 8-2. PR 作成

```bash
gh pr create --title "Migrate to Azure Storage + GitHub Actions" --body "Resolves #<issue>"
```

### 8-3. Plan job 確認

```bash
gh pr checks
```

### 8-4. マージと Apply job 確認

```bash
gh pr merge --squash
gh run list --limit 1
```

## Phase 9: クリーンアップ

### 9-1. Terraform Cloud VCS 連携を削除

Terraform Cloud Web UI で:
1. ワークスペースの Settings → Version Control に移動
2. "Disconnect from version control" をクリック

### 9-2. Terraform Cloud ワークスペースを削除（オプション）

Settings → Destruction and Deletion → Delete workspace

### 9-3. imports.tf を移動

```bash
mv imports.tf imports.tf.completed
```

### 9-4. ローカルバックアップを整理

```bash
mkdir -p backups
mv terraform.tfstate.*.backup backups/
```

## トラブルシューティング

### Terraform Cloud からの直接移行不可

`terraform init -migrate-state` が Terraform Cloud からは動作しない場合があります。

**解決策**: `terraform state pull` でバックアップ → local backend で state を復元 → azurerm backend へ移行

### Import ID 形式

- Azure AD Application: `/applications/{object_id}` 形式が必要
- Federated Credential: `{application_id}/federatedIdentityCredential/{credential_id}` 形式が必要

### ARM_USE_OIDC エラー

GitHub Actions で以下のエラーが出る場合:

```
Error: Error building ARM Config: Authenticating using the Azure CLI is only supported as a User
```

**解決策**: `terraform init` と `terraform plan/apply` に以下の環境変数を追加:

```yaml
env:
  ARM_USE_OIDC: true
  ARM_CLIENT_ID: ${{ env.AZURE_CLIENT_ID }}
  ARM_TENANT_ID: ${{ env.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ env.AZURE_SUBSCRIPTION_ID }}
```

### 1Password Service Account トークンエラー

```
error initializing client: Validation: (failed to session.DecodeSACredentials)
```

**解決策**: GitHub Environment Secret `OP_SERVICE_ACCOUNT_TOKEN` の値を再設定

## 参考

- [Azure Storage Backend Documentation](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
- [GitHub Actions OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [1Password Service Accounts](https://developer.1password.com/docs/service-accounts/)
