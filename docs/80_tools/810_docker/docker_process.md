# Docker操作手順・チートシート
## 1. 目的・概要
### 1.1 本資料の目的
- Dockerの概要・導入手順・設定手順・利用方法を忘備録として記す
- よく使うコマンドを目的別に整理し、必要な時にすぐ引けるチートシートとする

### 1.2 Dockerの概要
- アプリケーションとその実行環境(ライブラリ・依存関係・設定等)を「コンテナ」という単位でパッケージ化し、どの環境でも同じ挙動で動かすためのプラットフォーム
- 主な構成要素
  - イメージ(Image): コンテナの実行に必要なファイル一式を含む読み取り専用のテンプレート
  - コンテナ(Container): イメージから生成される実行インスタンス。起動・停止・削除が可能
  - Dockerfile: イメージのビルド手順を記述するテキストファイル
  - レジストリ(Registry): イメージを保管・配布する場所(Docker Hub等)
  - ボリューム(Volume): コンテナのライフサイクルに依存しないデータ永続化の仕組み
  - ネットワーク(Network): コンテナ間・外部との通信を制御する仕組み
- 仮想マシン(VM)との違い
  - VMはハードウェアごと仮想化しゲストOSを丸ごと起動するため重い
  - Dockerはホストのカーネルを共有し、プロセスレベルで隔離するため軽量・高速に起動できる
- 参考資料
  - https://docs.docker.com/
  - https://docs.docker.com/get-started/

## 2. 導入手順
### 2.1 前提条件
- OS
  - Windows 10/11(WSL2必須)、macOS、Linux
- Windowsの場合
  - WSL2の有効化
  - > wsl --install
  - > wsl --version

### 2.2 インストール
#### 2.2.1 Windows/macOS(Docker Desktop)
- 以下URLからDocker Desktopをダウンロード
  - https://www.docker.com/products/docker-desktop/
- インストーラを実行し、案内に従ってセットアップ
  - Windowsの場合、バックエンドに「WSL2」を選択(推奨)
- インストール後、Docker Desktopを起動し、タスクトレイのアイコンが起動状態(緑)になることを確認

#### 2.2.2 Linux(Docker Engine)
- 公式スクリプトでインストール
  - > curl -fsSL https://get.docker.com -o get-docker.sh
  - > sudo sh get-docker.sh
- sudoなしでdockerコマンドを実行したい場合
  - > sudo usermod -aG docker $USER
  - 一度ログアウト・再ログインして反映

### 2.3 インストール確認
- > docker --version
- > docker compose version    # Compose V2(dockerコマンドのサブコマンドとして統合済み)
- > docker run hello-world    # 動作確認用の公式イメージを取得・実行

## 3. 設定手順
### 3.1 Docker Desktopの基本設定(GUI)
- Settings > General
  - Start Docker Desktop when you log in: 起動時の自動起動有無
- Settings > Resources
  - CPU数・メモリ・ディスクの割り当てを調整(WSL2バックエンドの場合は`.wslconfig`でも調整可能)
- Settings > Resources > WSL Integration
  - 対象のWSLディストリビューションでDockerを使えるように有効化

### 3.2 レジストリへのログイン
- > docker login                          # Docker Hubへのログイン
- > docker login <レジストリURL>          # プライベートレジストリ・ECR等へのログイン
- > docker logout

### 3.3 Dockerfileの基本構成
- プロジェクトルートに`Dockerfile`を作成
```
FROM node:22-slim          # ベースイメージ
WORKDIR /app                # 作業ディレクトリ
COPY package*.json ./       # 依存関係定義のみ先にコピー(レイヤーキャッシュ活用)
RUN npm ci                  # 依存関係のインストール
COPY . .                    # 残りのソースをコピー
EXPOSE 3000                 # コンテナが利用するポート(ドキュメント目的)
CMD ["npm", "start"]        # コンテナ起動時に実行するコマンド
```
- レイヤーキャッシュを効かせるため、変更頻度の低い命令(依存関係インストール等)を先に、変更頻度の高いソースコードのコピーを後に書く

### 3.4 .dockerignoreの設定
- ビルドコンテキストに含めたくないファイルを指定(`.gitignore`と同様の書式)
```
node_modules
.git
.env
*.log
```

### 3.5 環境変数の設定
- Dockerfile内で既定値を設定
  - > ENV NODE_ENV=production
- 実行時に個別指定
  - > docker run -e KEY=VALUE <イメージ名>
- ファイルでまとめて指定
  - > docker run --env-file .env <イメージ名>
  - `.env`は`.gitignore`に含め、リポジトリへコミットしない

## 4. 利用方法(日常の操作フロー)
### 4.1 イメージのビルド
- > docker build -t <イメージ名>:<タグ> .
  - `-t`: イメージ名とタグを指定(タグ省略時は`latest`)
  - `.`: ビルドコンテキスト(Dockerfileのある場所)
- > docker build --no-cache -t <イメージ名>:<タグ> .   # キャッシュを使わずビルド

### 4.2 イメージの管理
- > docker images                     # ローカルイメージ一覧
- > docker rmi <イメージ名またはID>   # イメージ削除
- > docker pull <イメージ名>:<タグ>   # レジストリから取得
- > docker push <イメージ名>:<タグ>   # レジストリへ送信(要事前login)
- > docker tag <元イメージ> <新イメージ名>:<タグ>   # タグ付け(pushの前段でよく使用)

### 4.3 コンテナの起動・操作
- > docker run <イメージ名>                       # コンテナを起動(フォアグラウンド)
- > docker run -d <イメージ名>                    # バックグラウンド起動(デタッチモード)
- > docker run -d -p <ホスト側ポート>:<コンテナ側ポート> <イメージ名>   # ポートフォワーディング
- > docker run -d -v <ホスト側パス>:<コンテナ側パス> <イメージ名>       # ボリュームマウント(bind mount)
- > docker run -it <イメージ名> /bin/bash         # 対話モードでシェルに入って起動
- > docker run --name <コンテナ名> <イメージ名>   # コンテナに名前を付けて起動
- > docker run --rm <イメージ名>                  # 終了時にコンテナを自動削除

### 4.4 コンテナの管理
- > docker ps                         # 実行中コンテナ一覧
- > docker ps -a                      # 停止中も含めた全コンテナ一覧
- > docker stop <コンテナ名またはID>  # コンテナ停止
- > docker start <コンテナ名またはID> # 停止中コンテナの再開
- > docker restart <コンテナ名またはID>
- > docker rm <コンテナ名またはID>    # コンテナ削除(停止済みのみ)
- > docker rm -f <コンテナ名またはID> # 強制削除(実行中でも削除)

### 4.5 コンテナ内の調査・デバッグ
- > docker logs <コンテナ名またはID>       # 標準出力ログの確認
- > docker logs -f <コンテナ名またはID>    # ログをリアルタイム追跡
- > docker exec -it <コンテナ名またはID> /bin/bash   # 実行中コンテナにシェルで入る
- > docker inspect <コンテナ名またはID>    # 詳細情報(設定・ネットワーク等)をJSONで表示
- > docker stats                           # 実行中コンテナのリソース使用状況(CPU/メモリ等)をリアルタイム表示

### 4.6 Docker Compose(複数コンテナの一括管理)
- プロジェクトルートに`docker-compose.yml`を作成
```yaml
services:
  web:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app
    env_file:
      - .env
    depends_on:
      - db
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: example
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```
- 主なコマンド
  - > docker compose up -d          # 全サービスをバックグラウンドで起動(必要に応じ自動ビルド)
  - > docker compose up -d --build  # イメージを再ビルドしてから起動
  - > docker compose down           # 全サービスを停止・コンテナ削除(ボリュームは維持)
  - > docker compose down -v        # ボリュームも含めて削除
  - > docker compose ps             # サービスの状態一覧
  - > docker compose logs -f <サービス名>   # 特定サービスのログ追跡
  - > docker compose exec <サービス名> /bin/bash   # 実行中サービスにシェルで入る

### 4.7 ボリューム・ネットワークの管理
- > docker volume ls                        # ボリューム一覧
- > docker volume rm <ボリューム名>         # ボリューム削除
- > docker network ls                       # ネットワーク一覧
- > docker network create <ネットワーク名>  # カスタムネットワーク作成
- > docker network connect <ネットワーク名> <コンテナ名>   # 実行中コンテナを別ネットワークへ接続

### 4.8 不要リソースの整理
- > docker system df                # Dockerが使用中のディスク容量の概要
- > docker container prune          # 停止中コンテナを一括削除
- > docker image prune              # タグなし(dangling)イメージを一括削除
- > docker image prune -a           # 未使用イメージを含め一括削除(要注意)
- > docker volume prune             # 未使用ボリュームを一括削除(要注意、データ消失に注意)
- > docker system prune -a          # コンテナ・イメージ・ネットワーク等をまとめて整理(要注意)

## 5. トラブルシューティング
### 5.1 ポートが既に使用中と言われる
- ホスト側ポートが他プロセスと衝突している
  - > docker ps                      # 既存コンテナが使用していないか確認
  - ホスト側の別ポートに変更して起動(例: `-p 3001:3000`)

### 5.2 ビルドしても変更が反映されない
- キャッシュが古い変更を保持している可能性
  - > docker build --no-cache -t <イメージ名>:<タグ> .
- `.dockerignore`で必要なファイルまで除外していないか確認

### 5.3 コンテナがすぐに終了してしまう
- > docker logs <コンテナ名またはID>   # 終了直前のログ・エラーを確認
- フォアグラウンドで実行するプロセス(メインプロセス)が存在しないと、コンテナは終了する仕様であることに注意

### 5.4 ディスク容量を圧迫している
- > docker system df                # 内訳を確認
- > docker system prune -a          # 未使用リソースを整理(実行前に対象を確認)

### 5.5 Windows(WSL2)でパフォーマンスが悪い
- プロジェクトファイルをWindows側(`/mnt/c/...`)ではなく、WSL2のLinuxファイルシステム内(`\\wsl.localhost\...`配下等)に置くとI/O性能が改善する場合がある

## 6. 用語・注意点まとめ
- イメージとコンテナの関係: イメージはクラス、コンテナはそのインスタンスに相当する
- レイヤー: Dockerfileの各命令ごとに生成される差分。変更のない命令はキャッシュが再利用されビルドが高速化される
- `docker run`は「イメージが無ければpull→コンテナ生成→起動」を一括で行う。既存コンテナの再開には`docker start`を使う
- `-v`(bind mount)はホストのパスをそのままコンテナに反映するため開発時の変更即時反映に向き、名前付きボリュームはDocker管理下でデータを永続化したい場合(DBデータ等)に向く
- `prune`系コマンドや`docker volume rm`はデータを復元困難な形で削除するため、実行前に対象を必ず確認する

## 7. コンテナ-手元端末間の通信トラブルシューティング
### 7.1 コンテナ内から手元端末(ホスト)に接続できない
- コンテナ内で`localhost`/`127.0.0.1`を指定すると、コンテナ自身のループバックを指してしまい、ホストへは届かない(ホストとコンテナは別ネットワーク上にある点に注意)
- 対処
  - Docker Desktop(Windows/Mac)の場合、ホストを指す特別なDNS名`host.docker.internal`を使用する
    - 例: コンテナ内のアプリから`http://host.docker.internal:<ホスト側で待受中のポート>`へアクセス
  - Linux(Docker Engine)の場合、`host.docker.internal`は既定で使えないため、以下いずれかで対応する
    - コンテナ起動時に明示的に追加
      - > docker run --add-host=host.docker.internal:host-gateway ...
    - `docker-compose.yml`に追記
      ```yaml
      extra_hosts:
        - "host.docker.internal:host-gateway"
      ```
    - もしくはホストのネットワークインターフェースIP(`ip addr`等で確認)を直接指定する
  - ホスト側アプリが`127.0.0.1`のみでlistenしている場合、別ネットワークにいるコンテナからは原理的に到達できないため、ホスト側アプリを`0.0.0.0`でlistenするよう変更する
  - ホストのファイアウォール(Windows Defender ファイアウォール等)が対象ポートをブロックしていないか確認する

### 7.2 手元端末(ホスト)からコンテナに接続できない
- ポートフォワーディング(`-p`オプション)を指定せずに起動していないか確認する
  - > docker ps    # PORTS列でホスト側ポートが割り当てられているか確認
  - 未指定の場合、コンテナを`-p <ホスト側ポート>:<コンテナ側ポート>`付きで起動し直す
- コンテナ内のアプリが`127.0.0.1`(コンテナ自身のループバック)でlistenしていると、`-p`でポートを公開してもホストから到達できない
  - コンテナ内アプリの設定を`0.0.0.0`でlistenするよう変更する(例: Flaskは`app.run(host="0.0.0.0")`、Node.js/Expressは`app.listen(PORT, "0.0.0.0")`)
- ポート番号の書き間違い、ホスト側ポートの重複がないか確認する
  - > docker port <コンテナ名またはID>   # 実際のポートマッピングを表示

### 7.3 確認用コマンド
- コンテナ内からの疎通確認
  - > docker exec -it <コンテナ名またはID> curl -v http://host.docker.internal:<ポート>
  - > docker exec -it <コンテナ名またはID> ping <確認先ホスト>
- コンテナのネットワーク設定確認
  - > docker inspect <コンテナ名またはID>          # NetworkSettings配下でIPアドレス・ポート設定を確認
  - > docker network inspect <ネットワーク名>      # 参加中のコンテナ・サブネットを確認
- ホスト側からの疎通確認
  - > curl -v http://localhost:<ホスト側ポート>

### 7.4 Docker Compose利用時の注意
- Compose内の複数サービス間は、サービス名がそのままホスト名として名前解決される(同一Composeネットワーク内限定)
  - 例: `db`サービスへは、他サービスから`http://db:5432`でアクセス可能
- 手元端末(ホスト)からComposeのサービスへは、上記のサービス名では到達できず、`ports`で公開したホスト側ポート経由でアクセスする必要がある

### 7.5 WSL2特有の注意点(Windows)
- WSL2とWindows(ホストOS)は別々の仮想ネットワークを持つが、Docker Desktopのミラーリング機能により`localhost`同士の転送は多くの場合自動で解決される
- 自動転送がうまく働かない場合、`%USERPROFILE%\.wslconfig`に以下を追記しWSLを再起動する
  ```
  [wsl2]
  networkingMode=mirrored
  ```
  - > wsl --shutdown    # 設定反映のためWSLを再起動
