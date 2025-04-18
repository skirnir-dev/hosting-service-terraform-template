## cf-terraforming によるインポートプロンプト

事前に以下の環境変数が設定されているものとします
- CLOUDFLARE_API_TOKEN
- CLOUDFLARE_ZONE_ID

### cf-terraforming コマンドによる import ブロック及び resource の生成

以下のコマンドを実行を実行し、 import ブロック及び resource を imports.tf に生成してください

```
cf-terraforming import --resource-type "cloudflare_record" --modern-import-block > imports.tf
cf-terraforming generate --resource-type "cloudflare_record" >> imports.tf
```

### import ブロックの修正と resource の移動

**TODO: 一旦インポートしてから moved ブロックで移動した方が確実**

import.tf に cf-terraforming でインポートした resource と import ブロックがあります。リソース名はランダムな文字列になっています。
最終的に modules/cloudflare_dns/main.ts へインポートしたいと思います。

1. ランダムな文字列になっているインポート名を modules/cloudflare_dns/main.ts で使用しているインポート名に修正してください
2. modules/cloudflare_dns/main.ts には存在しないリソースがあった場合は `<type>_<subdomain>` でリソース名を作成してください
3. import ブロックの to は module.cloudflare_dns へインポート可能な形式へ変換してください
4. A レコードのリソース名は、 `a_<サブドメイン>` ではなく、サブドメインのみにしてください
5. value は非推奨となっています。 content としてください
6. resource ブロックのリソース名も import ブロックと一致するよう修正してください
7. modules/cloudflare_dns/main.ts に存在する imports.tf のリソースブロックはコメントアウトしてください
8. content と zone_id は modules/cloudflare_dns/main.ts に一致するよう修正してください
9. imports.tf の modules/cloudflare_dns/main.ts には存在しないリソースを modules/cloudflare_dns/main.ts に移動してください
10. main.tf に移動した imports.tf のリソースをコメントアウトしてください
11. imports.tf のコメントアウトされていないリソースを、すべて modules/cloudflare_dns/main.ts へ移動してください
12. imports.tf のすべてのリソースをコメントアウトしてください

