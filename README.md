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


