# Vercel環境構築
## 1. 目的・概要
### 1.1 本資料の目的
- Vercelの導入方法や利用方法を忘備録として記す

### 1.2 Vercelの概要
- VercelはモダンなWebアプリケーションをビルドしてデプロイするためのクラウド
  - 自製したサイト・アプリをインターネット上に公開
  - パブリックにアクセス可能なURLを自動で発行
  - パブリックに配信
- Github連携に強く、Githubリポジトリと連携するとpush毎に自動デプロイが可能
- 参考資料
  - https://vercel.com/docs/getting-started-with-vercel
  - https://note.com/chujo/n/nd6abc2626322
  - https://qiita.com/YushiYamamoto/items/0957d6ea1b3b3eed10fb
  - https://zenn.dev/umi_mori/books/next-js-typescript/viewer/deploying-to-vercel

## 2. 環境構築
### 2.1 前提条件
- 開発環境
  - nodejs v22+
- Gitリポジトリ
  - Github 他(GitLab、Bitbucketなど)
- Vercelアカウント
  - 無料(hobby)アカウントで良い

### 2.2 環境構築手順
#### 2.2.1 Vercelアカウント作成
- 以下URLを表示
  - https://vercel.com/
- Sign up > Github で認証
- 必要情報を入力し、アカウントの有効化

#### 2.2.2 プロジェクトの作成
- Vercelのダッシュボードで、Add New > Projectをクリック
- Gitリポジトリの選択
- import > Continue
- ビルド設定は自動検出のため、そのままDeploy
  - vercel.jsonをプロジェクトルートに配置すると、カスタム可能
  - next.config.js(Next.js)なども自動検出

#### 2.2.3 デプロイの確認
- Vercelがビルドログを表示し、完了後にURLが提示される
- ブラウザでhttps://[project-name].vercel.appを開く
- 変更をgit pushすると、Vercelが自動で再デプロイ

#### 2.2.4 カスタムドメイン設定(任意、調査のみ)
- サイドメニュー > Domains へ移動
- Add > カスタムドメイン入力
- DNS で CNAME（サブドメイン）または A レコード（ルートドメイン）を設定
- 設定が反映されるまで数分待つ

#### 2.2.5 環境変数の整理
- サイドメニュー > Environment Variables へ移動
- Add Environment Variableをクリック
  - Key、Value、Noteを入力
  - Production、Previewを設定
  - Saveする
- Vercelはデプロイの時に自動で環境変数を設定

#### 2.2.6 サーバレス関数の利用(e.g. Next.js API Routes)
- TBD

### 2.3 確認事項
- 無料(hobby)アカウントの制限
  - デプロイ回数100回/日、ビルド時間は45分まで
- サーバレス関数の実行時間制限
  - 無料アカウントで300sまで

## 3. GitHub Actions / GitHub Pagesとの連携(ブラウザ設定のみ)
### 3.1 本章の方針
- ワークフローYAML(`.github/workflows/*.yml`)を新規作成せず、VercelダッシュボードとGitHubのWeb設定画面だけで完結する範囲に限定する
- lint/testを挟む等の独自ビルドパイプラインを組みたい場合、原則としてYAMLでのワークフロー定義が必須となるため本章の対象外(必要になったら別途手順化する)

### 3.2 Vercel既定のGitHub連携(ブラウザ設定のみ)
- 2.2.2のプロジェクトImport時点で、Vercel公式のGitHub App(「Vercel」App)がリポジトリにインストールされ、以下が自動で有効になる
  - pushの度の自動ビルド・デプロイ(Production/Preview)
  - PRへのデプロイURL・ビルド結果コメントの自動投稿
  - コミットステータス/チェックの自動付与
- 追加で設定できる項目(すべてVercelダッシュボードのみで完結)
  - Settings > Git > Production Branch
    - 本番デプロイ対象ブランチの変更
  - Settings > Git > Build and Deployment > Ignored Build Step
    - 特定条件でビルドをスキップする条件をコマンド入力欄に記述(コマンド1行のみで、リポジトリへのファイル追加は不要)
  - Settings > Git > Deploy Hooks
    - 特定ブランチ向けのWebhook URLを発行し、外部トリガーでデプロイを起動
  - Settings > Environments
    - Production/Preview/Developmentごとの環境変数を分離
- GitHub側でVercelのビルド成功をマージ必須条件にしたい場合
  - GitHubリポジトリの Settings > Branches > Branch protection rules で対象ブランチを選択
  - 「Require status checks to pass before merging」を有効化し、一覧からVercelのチェック(例: `Vercel – <project-name>`)を選択
  - これによりVercelのビルド成功がマージの必須条件になる(YAMLファイル不要)

### 3.3 GitHub Pagesとの連携(ブラウザ設定のみ)
- 位置づけ
  - Vercelと同時に使うものではなく、静的サイト限定の代替ホスティング先
  - サーバレス関数・SSR・ISRなど動的機能が不要な静的サイトであれば、Vercelの代わりにGitHub Pagesへ配信できる
- 設定手順(Deploy from a branch方式、ワークフローYAML不要)
  1. GitHubリポジトリの Settings > Pages を開く
  2. Build and deployment > Source を「Deploy from a branch」に設定
  3. Branch欄で公開対象ブランチ(例: main)とフォルダ(`/ (root)`または`/docs`)を選択してSave
  4. 数分待つとページ上部に公開URL(`https://<owner>.github.io/<repo>/`)が表示される
- 補足
  - Markdownファイルをそのまま置く場合、GitHub標準のJekyllが自動でHTML化する。Jekyll処理を行わず生ファイルをそのまま配信したい場合は、公開対象フォルダ直下にGitHubのWeb UI(Add file > Create new file)で空の`.nojekyll`ファイルを作成する
  - カスタムドメインは同じSettings > Pages画面のCustom domain欄で設定可能(DNS側の設定は2.2.4と同様)
- 注意
  - 「Source」を「GitHub Actions」に変更するとテンプレートワークフローの追加が必須になるため、YAML不要の方針では選択しない(「Deploy from a branch」を選ぶこと)
- Vercelとの使い分けの目安
  - Vercel: サーバレス関数・ISR・プレビューデプロイ等の動的機能が必要な場合
  - GitHub Pages: 完全に静的なサイトで、Vercelの無料枠(ビルド時間・関数実行時間等)を消費したくない場合

