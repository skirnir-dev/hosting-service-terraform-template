# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

AzureのVMベースのホスティングサービスをTerraformとAnsibleで構築するためのテンプレートリポジトリです。CloudflareやSendGrid、Mackerelなどの外部サービスと統合し、WordPressやEC-CUBEなどのWebアプリケーションをホスティングできます。

## よく使うコマンド

### Terraform操作

```bash
# ローカル開発での実行（1Password CLI で secrets を取得）
export TF_VAR_cloudflare_api_token=$(op read "op://<project>-infrastructure/terraform-secrets/cloudflare_api_token")
export TF_VAR_sendgrid_api_key=$(op read "op://<project>-infrastructure/terraform-secrets/sendgrid_api_key")
export TF_VAR_mackerel_api_key=$(op read "op://<project>-infrastructure/terraform-secrets/mackerel_api_key")

terraform init
terraform plan
terraform apply

# ローカルでtfstateを取得（Ansible inventoryで使用）
terraform state pull > terraform.tfstate
```

### Ansible操作

```bash
# 秘密鍵ファイルを暗号化
ansible-vault encrypt ansible/key.yml

# Playbookを実行
ansible-playbook -i inventory.yml playbook.yml --diff --ask-vault-pass

# 暗号化されたファイルを編集
ansible-vault edit ansible/key.yml
```

### cf-terraforming（Cloudflare DNSリソースのインポート）

```bash
# 環境変数を設定
export CLOUDFLARE_API_TOKEN="your-api-token"
export CLOUDFLARE_ZONE_ID="your-zone-id"

# インポートブロックとリソースを生成
cf-terraforming import --resource-type "cloudflare_record" --modern-import-block > imports.tf
cf-terraforming generate --resource-type "cloudflare_record" >> imports.tf
```

## アーキテクチャと構造

### Terraformモジュール構成

- **modules/github_actions/**: GitHub Actions OIDC認証、Terraform state用Storage Account
- **modules/vm/**: Azure VMとその関連リソース（OS disk、SSH key）を作成
- **modules/networks/**: VNet、サブネット、NSG、パブリックIPを管理
- **modules/backup/**: Recovery Services VaultとVMバックアップポリシーを設定
- **modules/insights/**: Application InsightsとWebテストを設定
- **modules/azure_dns/**: Azure DNSゾーンとレコードを管理（未使用の場合が多い）
- **modules/cloudflare_dns/**: Cloudflare DNSレコードとページルールを管理
- **modules/zero_trust/**: Cloudflare Zero Trust（Access）設定を管理
- **modules/waf/**: Cloudflare WAFルールを設定
- **modules/sendgrid/**: SendGridサブユーザーと認証設定を管理
- **modules/mackerel/**: Mackerel外形監視を設定

### Ansibleロール

playbook.ymlで以下の構成を行います：

1. **OS設定**: SELinux無効化、タイムゾーン設定、スワップ設定
2. **パッケージインストール**: Apache、PHP、MariaDB、PostgreSQL、必要なツール群
3. **SSL証明書**: Let's Encryptで本番・ステージング環境の証明書を取得
4. **Webサーバー設定**: VirtualHost設定、ディレクトリ権限設定
5. **WordPress対応**: wp-cli、SSH2拡張（自動更新用）のインストール
6. **開発ツール**: Composer、GitHub CLI、Git設定

### 重要な設定ファイル

- **providers.tf**: Azure Storage BackendとProviderの設定
- **variables.tf**: 変数定義（project_name、fqdn、username、location等）
- **ansible/var_files.yml**: Ansible変数（プロジェクト固有の設定）
- **ansible/key.yml**: 暗号化された秘密情報（DB パスワード等）
- **inventory.yml**: Terraformの状態から動的にインベントリを生成

## Backend設定（Azure Storage）

### 認証方法

**GitHub Actions (CI/CD)**:
- Azure OIDC認証を使用（Service Principal）
- 1Password Service Account で secrets 管理

**ローカル開発**:
- Azure CLI認証（`az login`）
- 1Password CLI で secrets 取得

### 1Password Vault 構成

**共通 Vault（skirnir-workload-identity）**:
- `azure-common-credentials`: AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID

**プロジェクト専用 Vault（<project>-infrastructure）**:
- `azure-credentials`: AZURE_CLIENT_ID
- `terraform-secrets`: cloudflare_api_token, sendgrid_api_key, mackerel_api_key

## 新規プロジェクトセットアップ

詳細は [README.md](./README.md) を参照してください。

### 概要

1. テンプレートからリポジトリを作成
2. Service Principal を手動作成（Bootstrap用）
3. 1Password Vault、Service Account を作成
4. GitHub Environment、Secret を設定
5. variables.tf、providers.tf を更新
6. Bootstrap実行（local backend → azurerm backend）
7. PR作成、Plan/Apply検証

### Bootstrap時のtargetリソース

```bash
terraform apply \
  -target=module.github_actions
```

## WordPress固有の設定

自動更新を有効にする場合、wp-config.phpに以下を追加：

```php
define('FS_METHOD', 'ssh2');
define('FTP_BASE', '/path/to/wp/');
define('FTP_CONTENT_DIR', '/path/to/wp/wp-content/');
define('FTP_PLUGIN_DIR ', '/path/to/wp/wp-content/plugins/');
define('FTP_PUBKEY', '/var/www/.ssh/id_rsa.pub');
define('FTP_PRIKEY', '/var/www/.ssh/id_rsa');
define('FTP_USER', '${adminUsername}');
define('FTP_HOST', 'localhost');
```

Gitで管理している場合は自動更新を許可：

```php
add_filter( 'automatic_updates_is_vcs_checkout', '__return_false', 1 );
```

## cf-terraforming によるインポートプロンプト

- `@modules/cloudflare_dns/import-cf-terraforming.md` を参照してください

## トラブルシューティング

### よくある問題

1. **Azure認証エラー**
   - GitHub Actions: `OP_SERVICE_ACCOUNT_TOKEN`シークレットを確認
   - ローカル: `az login`で再認証、または1Password CLIで認証情報を再取得

2. **Backend初期化エラー**
   - Storage Accountが存在することを確認
   - Azure CLI認証が有効であることを確認
   - Service Principalに`Storage Blob Data Contributor`権限があることを確認

3. **1Password認証エラー**
   - ローカル: `op signin`で再認証
   - GitHub Actions: Service Accountトークンの有効期限を確認

4. **GitHub Actions OIDC エラー**
   - `ARM_USE_OIDC=true`が設定されていることを確認
   - Federated Identity Credentialのsubjectが正しいことを確認
