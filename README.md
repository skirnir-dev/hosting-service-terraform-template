# hosting-service-terraform-template

AzureのVMベースのホスティングサービスをTerraformとAnsibleで構築するためのテンプレートリポジトリです。

## アーキテクチャ

### インフラ構成

```
顧客プロジェクト
├── Azure Resources
│   ├── Resource Group: <fqdn>
│   ├── Virtual Machine (Linux)
│   ├── Virtual Network / Subnet / NSG
│   ├── Public IP
│   ├── Recovery Services Vault (Backup)
│   └── Application Insights
│
├── Cloudflare
│   ├── DNS Records
│   ├── Zero Trust (Access)
│   └── WAF Rules
│
├── SendGrid
│   └── Subuser + Domain Authentication
│
└── Mackerel
    └── External Monitoring
```

### CI/CD アーキテクチャ（完全独立構成）

各プロジェクトが完全に独立した構成を持ちます:

```
<project>-terraform リポジトリ
├── Azure Service Principal: <project>-terraform (独自)
│   ├── Contributor (scope: Subscription)
│   ├── User Access Administrator (scope: Resource Group)
│   ├── Storage Blob Data Contributor (scope: Storage Account)
│   └── Federated Credential: GitHub Actions
│
├── Azure Storage: state<project> (独自)
│   └── Container: tfstate
│
├── 1Password Service Account: github-actions-<project> (独自)
│   ├── skirnir-workload-identity Vault (読み取り)
│   └── <project>-infrastructure Vault (読み取り)
│
└── 1Password Vaults:
    ├── skirnir-workload-identity (共通)
    │   ├── AZURE_TENANT_ID
    │   └── AZURE_SUBSCRIPTION_ID
    └── <project>-infrastructure (プロジェクト専用)
        ├── AZURE_CLIENT_ID
        ├── cloudflare_api_token
        ├── sendgrid_api_key
        └── mackerel_api_key
```

### 設計の利点

1. **完全な独立性**: プロジェクト間の依存なし
2. **Rate Limit 解決**: 各 SP は 1 つの Federated Credential のみ
3. **セキュリティ**: 最小権限の原則、影響範囲の局所化
4. **運用性**: プロジェクト削除時に全リソースをまとめて削除可能
5. **スケーラビリティ**: 新規顧客への展開が容易

## 新規顧客セットアップ手順

### 前提条件

- Azure CLI (`az`)
- 1Password CLI (`op`)
- GitHub CLI (`gh`)
- Terraform CLI

### Phase 0: リポジトリ作成

```bash
# テンプレートからリポジトリを作成
gh repo create skirnir-dev/<project>-terraform --clone --private --template skirnir-dev/hosting-service-terraform-template
cd <project>-terraform
```

### Phase 1: Service Principal 手動作成（Bootstrap）

Storage Account 作成前に必要な Service Principal を手動で作成します。

```bash
# 1. Azure AD Application 作成
az ad app create --display-name "<project>-terraform"
APP_ID=$(az ad app list --display-name "<project>-terraform" --query "[0].appId" -o tsv)
OBJECT_ID=$(az ad app list --display-name "<project>-terraform" --query "[0].id" -o tsv)

# 2. Service Principal 作成
az ad sp create --id $APP_ID
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query "id" -o tsv)

# 3. Federated Credential 追加（GitHub Actions用）
az ad app federated-credential create \
  --id $OBJECT_ID \
  --parameters '{
    "name": "<project>-github-actions",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:skirnir-dev/<project>-terraform:environment:production",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# 4. Subscription レベルで Contributor 権限付与
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID

# 5. 値を記録
echo "AZURE_CLIENT_ID: $APP_ID"
echo "SP_OBJECT_ID: $SP_OBJECT_ID"
```

### Phase 2: 1Password Vault とアイテム作成

```bash
# 1. プロジェクト専用 Vault 作成
op vault create <project>-infrastructure

# 2. Azure認証情報アイテム作成
op item create --category="API Credential" --title="azure-credentials" \
  --vault="<project>-infrastructure" \
  "AZURE_CLIENT_ID=$APP_ID"

# 3. Terraform secrets アイテム作成
op item create --category="API Credential" --title="terraform-secrets" \
  --vault="<project>-infrastructure" \
  "cloudflare_api_token=<token>" \
  "sendgrid_api_key=<key>" \
  "mackerel_api_key=<key>"

# 4. 共通認証情報の確認（既存の skirnir-workload-identity Vault）
op item get azure-common-credentials --vault=skirnir-workload-identity
```

### Phase 3: 1Password Service Account 作成

```bash
# プロジェクト専用の Service Account を作成
op service-account create "github-actions-<project>" \
  --vault "skirnir-workload-identity:read_items" \
  --vault "<project>-infrastructure:read_items"

# トークンを安全に保存（一度だけ表示される）
```

### Phase 4: GitHub Environment と Secret 設定

```bash
# Environment 作成
gh api repos/skirnir-dev/<project>-terraform/environments/production --method PUT

# Secret 設定
gh secret set OP_SERVICE_ACCOUNT_TOKEN \
  --repo skirnir-dev/<project>-terraform \
  --env production
# プロンプトで Service Account トークンを入力
```

### Phase 5: Terraform 設定

```bash
# 1. variables.tf のプロジェクト固有値を設定
#    - project_name, fqdn, username など

# 2. providers.tf の backend 設定を確認
#    - storage_account_name, key などを確認

# 3. ansible/var_files.yml を設定
```

### Phase 6: Bootstrap 実行（local backend → azurerm backend）

```bash
# 1. providers.tf の backend ブロックをコメントアウト

# 2. local backend で初期化
terraform init

# 3. github_actions モジュールを作成（targeted apply）
terraform apply -target=module.github_actions

# 4. azure_client_id を 1Password に保存（必要に応じて）
terraform output azure_client_id

# 5. local state をバックアップ
cp terraform.tfstate terraform.tfstate.local.backup

# 6. providers.tf の backend ブロックをコメント解除
#    storage_account_name は terraform output storage_account_name で確認

# 7. azurerm backend に移行
terraform init -migrate-state

# 8. 残りのリソースを適用
terraform apply
```

### Phase 7: 検証

```bash
# PR を作成して Plan job を確認
git checkout -b test/initial-setup
git add .
git commit -m "feat: initial infrastructure setup"
git push -u origin test/initial-setup
gh pr create --title "Initial infrastructure setup" --body "Setup for <project>"

# Plan job の成功を確認
gh pr checks

# マージして Apply job を確認
gh pr merge --squash
gh run list --limit 1
```

## Ansible でサーバー構成

```bash
# terraform.tfstate を取得（Ansible inventory で使用）
terraform state pull > terraform.tfstate

# 秘密情報を暗号化
ansible-vault encrypt ansible/key.yml

# Playbook を実行
ansible-playbook -i inventory.yml playbook.yml --diff --ask-vault-pass
```

## WordPress の自動更新設定

```php
// wp-config.php
define('FS_METHOD', 'ssh2');
define('FTP_BASE', '/path/to/wp/');
define('FTP_CONTENT_DIR', '/path/to/wp/wp-content/');
define('FTP_PLUGIN_DIR ', '/path/to/wp/wp-content/plugins/');
define('FTP_PUBKEY', '/var/www/.ssh/id_rsa.pub');
define('FTP_PRIKEY', '/var/www/.ssh/id_rsa');
define('FTP_USER', '${adminUsername}');
define('FTP_HOST', 'localhost');
```

Git で管理している場合:

```php
// wp-content/themes/themeName/functions.php
add_filter( 'automatic_updates_is_vcs_checkout', '__return_false', 1 );
```

## ディレクトリ構造

```
.
├── .github/workflows/
│   └── terraform.yml      # GitHub Actions ワークフロー
├── ansible/
│   ├── key.yml            # 暗号化された秘密情報
│   ├── roles/             # Ansible ロール
│   └── var_files.yml      # プロジェクト固有変数
├── modules/
│   ├── azure_dns/         # Azure DNS
│   ├── backup/            # Recovery Services Vault
│   ├── cloudflare_dns/    # Cloudflare DNS
│   ├── insights/          # Application Insights
│   ├── mackerel/          # Mackerel 監視
│   ├── networks/          # VNet, Subnet, NSG
│   ├── sendgrid/          # SendGrid
│   ├── vm/                # Virtual Machine
│   ├── waf/               # Cloudflare WAF
│   └── zero_trust/        # Cloudflare Zero Trust
├── ci-cd.tf               # Service Principal, Storage Account
├── main.tf                # メインリソース定義
├── providers.tf           # Provider と Backend 設定
├── variables.tf           # 変数定義
├── inventory.yml          # Ansible inventory
└── playbook.yml           # Ansible playbook
```

## 関連ドキュメント

- [CLAUDE.md](./CLAUDE.md) - Claude Code 向けガイダンス
- [docs/migration-from-terraform-cloud.md](./docs/migration-from-terraform-cloud.md) - Terraform Cloud からの移行手順
