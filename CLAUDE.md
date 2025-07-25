# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

AzureのVMベースのホスティングサービスをTerraformとAnsibleで構築するためのテンプレートリポジトリです。CloudflareやSendGrid、Mackerelなどの外部サービスと統合し、WordPressやEC-CUBEなどのWebアプリケーションをホスティングできます。

## よく使うコマンド

### Terraform操作

```bash
# Terraform Cloud経由でデプロイ
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

- **providers.tf**: Terraform Cloudとプロバイダーの設定
- **variables.tf**: 変数定義（fqdn、username、location等）
- **ansible/var_files.yml**: Ansible変数（プロジェクト固有の設定）
- **ansible/key.yml**: 暗号化された秘密情報（DB パスワード等）
- **inventory.yml**: Terraformの状態から動的にインベントリを生成

## 新規プロジェクトセットアップ手順

1. リポジトリをテンプレートから作成
2. Terraform Cloudでworkspaceを作成
3. 必要な認証情報を設定（Azure、Cloudflare、SendGrid等）
4. providers.tfのworkspace名を更新
5. variables.tfでプロジェクト固有の値を設定
6. ansible/var_files.ymlを編集
7. Terraformでインフラをデプロイ
8. Ansibleでサーバーを構成

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