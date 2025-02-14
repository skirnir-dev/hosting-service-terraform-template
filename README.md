# hosting-service-terraform-template

## Usage

1. このリポジトリをテンプレートにして、リポジトリを新規作成
   ```shell
   gh repo create skirnir-dev/<projectname>-terraform --clone --private --template skirnir-dev/hosting-service-terraform-template
   ```
2. Terraform cloud に workspace を作成
3. (MS Entra IDを使う場合) フェデレーション資格情報を作成
    - `TFC_AZURE_RUN_CLIENT_ID` も設定する 
4. (Cloudflareを使う場合) API キーを作成
5. (Cloudflareを使う場合) Terraform cloud に Cloudflare の API キーを設定
6. (SendGrid を使う場合) サブユーザーを作成
7. [providers.tf](./providers.tf) 及び [ansible/var_files.yml](./ansible/var_files.yml) を設定


### ansible

``` shell
## terraform.tfstate ファイルを出力しておくと、 terraform ansible プラグインで inventory の情報を生成できる
terraform state pull > terraform.tfstate
## ansible/key.yml を暗号化しておく
ansible-vault encrypt ansible/key.yml
ansible-playbook -i inventory.yml playbook.yml --diff --ask-vault-pass
```

### WordPress の自動更新を設定する

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

#### WordPress を Git で管理している場合は以下を追加

```php
// wp-content/themes/themeName/functions.php
add_filter( 'automatic_updates_is_vcs_checkout', '__return_false', 1 );
```
