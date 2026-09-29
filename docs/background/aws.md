# AWS 概要・チートシート・ベストプラクティス
## 1. 目的・概要
### 1.1 本資料の目的
- AWS(Amazon Web Services)の全体像・主要サービス・基本操作を忘備録として記す
- よく使うAWS CLIコマンド・設計指針を目的別に整理し、必要な時にすぐ引けるチートシートとする

### 1.2 AWSの概要
- Amazonが提供するクラウドコンピューティングプラットフォーム。サーバー・ストレージ・DB・ネットワーク等を、使った分だけ課金(従量課金)で利用できる
- 主な特徴
  - オンデマンド調達: 必要な時に数分でリソースを用意し、不要になれば削除できる
  - 責任共有モデル: 「クラウド"の"セキュリティ(物理・基盤)」はAWS、「クラウド"内の"セキュリティ(データ・設定・アクセス管理)」は利用者の責任
  - グローバルインフラ: リージョン(地理的なまとまり) > アベイラビリティゾーン(AZ、独立したデータセンター群) > エッジロケーション(CDN配信拠点)
- 主要な概念
  - リージョン(Region): `ap-northeast-1`(東京)、`us-east-1`(バージニア北部)等。サービス・料金・提供機能はリージョンごとに異なる
  - アベイラビリティゾーン(AZ): 1リージョン内の物理的に分離された複数拠点。複数AZに分散配置することで可用性を高める
  - アカウント: 課金とリソースの独立単位。用途・環境ごとに分け、AWS Organizationsで一元管理するのが一般的
  - IAM: 誰が何にアクセスできるかを制御する認証・認可の仕組み
- 参考資料
  - https://docs.aws.amazon.com/
  - https://aws.amazon.com/architecture/well-architected/
  - https://docs.aws.amazon.com/cli/latest/reference/

## 2. 主要サービス早見表
### 2.1 コンピューティング
- EC2: 仮想サーバー。OS込みで自由に構成できる。インスタンスタイプ(例: `t3.micro`)でCPU/メモリを選択
- Lambda: サーバー管理不要でコードを実行(サーバーレス)。イベント駆動、実行時間とメモリで課金
- ECS / Fargate: コンテナ実行基盤。FargateはEC2管理不要でコンテナを起動
- EKS: マネージドKubernetes
- App Runner / Elastic Beanstalk: ソースやコンテナを渡すだけでデプロイできるPaaS的サービス

### 2.2 ストレージ
- S3: オブジェクトストレージ。静的ファイル・バックアップ・データレイク等。高耐久(99.999999999%)、容量無制限
- EBS: EC2にアタッチするブロックストレージ(仮想ディスク)。AZ内に存在
- EFS: 複数EC2から同時マウントできるNFSファイルストレージ
- Glacier(S3 Glacier): 低コストなアーカイブ用ストレージクラス

### 2.3 データベース
- RDS: マネージドリレーショナルDB(MySQL / PostgreSQL / MariaDB / Oracle / SQL Server)
- Aurora: AWS製の高性能・高可用なMySQL/PostgreSQL互換DB
- DynamoDB: フルマネージドなNoSQL(キーバリュー / ドキュメント)。低レイテンシ、自動スケール
- ElastiCache: マネージドなRedis / Memcached(キャッシュ)
- Redshift: 分析用データウェアハウス(DWH)

### 2.4 ネットワーク
- VPC: 論理的に分離した仮想ネットワーク。サブネット・ルートテーブル・ゲートウェイで構成
- サブネット: VPC内のIP範囲。インターネットへ経路があるものをパブリック、ないものをプライベートと呼ぶ
- Security Group: インスタンス単位のステートフルなファイアウォール(許可ルールのみ)
- Network ACL: サブネット単位のステートレスなファイアウォール(許可・拒否)
- ELB(ALB / NLB): ロードバランサー。ALBはHTTP/HTTPS(L7)、NLBはTCP/UDP(L4)
- Route 53: DNSサービス。ドメイン管理・ヘルスチェック・ルーティングポリシー
- CloudFront: CDN。エッジからの配信でレイテンシ削減・オリジン負荷軽減
- API Gateway: REST / HTTP / WebSocket APIのフロント。認証・スロットリング・キャッシュ

### 2.5 セキュリティ・ID管理
- IAM: ユーザー・グループ・ロール・ポリシーによるアクセス制御
- IAM Identity Center(旧AWS SSO): 複数アカウント・アプリへのシングルサインオン
- KMS: 暗号鍵の管理。S3・EBS・RDS等の暗号化に利用
- Secrets Manager / SSM Parameter Store: 認証情報・設定値の安全な保管と取得
- WAF / Shield: Web攻撃対策 / DDoS対策
- GuardDuty / Security Hub / Inspector: 脅威検知 / 統合的なセキュリティ状況の可視化 / 脆弱性スキャン

### 2.6 監視・運用
- CloudWatch: メトリクス・ログ・アラーム・ダッシュボード
- CloudTrail: APIコール(誰が・いつ・何を)の監査ログ
- Config: リソース構成の変更履歴とコンプライアンス評価
- Systems Manager(SSM): パッチ適用・リモートコマンド実行・セッション管理

### 2.7 IaC・デプロイ
- CloudFormation: AWS純正のIaC(YAML / JSON)
- CDK: プログラミング言語(TypeScript等)でインフラを定義しCloudFormationを生成
- Terraform(サードパーティ): マルチクラウド対応の代表的IaC
- CodePipeline / CodeBuild / CodeDeploy: CI/CDパイプライン

### 2.8 メッセージング・連携
- SQS: フルマネージドなメッセージキュー(疎結合化・非同期処理)
- SNS: Pub/Sub型の通知(メール・SMS・HTTP・Lambda等へファンアウト)
- EventBridge: イベントバス。SaaS・AWSサービス間のイベント連携
- Step Functions: 複数処理をステートマシンとしてオーケストレーション

## 3. 導入・初期設定
### 3.1 AWS CLIのインストール
- 公式インストーラ(v2推奨)
  - Linux: `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"` → `unzip awscliv2.zip` → `sudo ./aws/install`
  - Windows: MSIインストーラを実行、またはwinget
    - > winget install -e --id Amazon.AWSCLI
  - macOS: `brew install awscli`
- 確認
  - > aws --version

### 3.2 認証情報の設定
- アクセスキーによる設定(個人検証など簡易な場合)
  - > aws configure
  - 入力項目: Access Key ID / Secret Access Key / Default region(例: `ap-northeast-1`) / Output format(例: `json`)
- 名前付きプロファイル(複数アカウント・環境の使い分け)
  - > aws configure --profile <プロファイル名>
  - 実行時に指定: `aws s3 ls --profile <プロファイル名>`
  - 環境変数で指定: `export AWS_PROFILE=<プロファイル名>`
- SSO(IAM Identity Center、推奨)
  - > aws configure sso
  - > aws sso login --profile <プロファイル名>
- 設定ファイルの場所
  - `~/.aws/config` / `~/.aws/credentials`(Windowsは`%USERPROFILE%\.aws\`)
- 現在の認証情報の確認
  - > aws sts get-caller-identity

### 3.3 認証情報の優先順位(上ほど優先)
- 1. コマンドラインオプション(`--profile`等)
- 2. 環境変数(`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN`)
- 3. `~/.aws/credentials`・`~/.aws/config`のプロファイル
- 4. コンテナ / EC2インスタンスプロファイル(IAMロール)

## 4. AWS CLI チートシート
### 4.1 共通オプション
- > aws <サービス> <コマンド> --region <リージョン>       # リージョン指定
- > aws <サービス> <コマンド> --profile <プロファイル名>   # プロファイル指定
- > aws <サービス> <コマンド> --output table              # 出力形式(json / table / text / yaml)
- > aws <サービス> <コマンド> --query "<JMESPath式>"      # 出力の絞り込み・整形
- > aws <サービス> help                                   # サービスのヘルプ
- > aws <サービス> <コマンド> --dry-run                    # 実行せず権限のみ確認(対応コマンドのみ)

### 4.2 S3
- > aws s3 ls                                   # バケット一覧
- > aws s3 ls s3://<バケット名>/<プレフィックス>/   # オブジェクト一覧
- > aws s3 mb s3://<バケット名>                  # バケット作成(make bucket)
- > aws s3 rb s3://<バケット名>                  # バケット削除(空である必要あり、--forceで中身ごと)
- > aws s3 cp <ローカルパス> s3://<バケット名>/<キー>       # アップロード
- > aws s3 cp s3://<バケット名>/<キー> <ローカルパス>       # ダウンロード
- > aws s3 sync <ローカルディレクトリ> s3://<バケット名>/<プレフィックス>/   # 差分同期
- > aws s3 sync s3://<バケット名>/ <ローカルディレクトリ> --delete          # 削除も反映して同期
- > aws s3 presign s3://<バケット名>/<キー> --expires-in 3600               # 署名付きURL発行
- 低レベルAPI(s3api)で詳細操作
  - > aws s3api get-bucket-versioning --bucket <バケット名>
  - > aws s3api put-public-access-block --bucket <バケット名> --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

### 4.3 EC2
- > aws ec2 describe-instances --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType,IP:PrivateIpAddress}" --output table
- > aws ec2 describe-instances --filters "Name=tag:Name,Values=<名前>" "Name=instance-state-name,Values=running"
- > aws ec2 start-instances --instance-ids <ID>
- > aws ec2 stop-instances --instance-ids <ID>
- > aws ec2 reboot-instances --instance-ids <ID>
- > aws ec2 terminate-instances --instance-ids <ID>        # 削除(復元不可、要注意)
- > aws ec2 describe-security-groups --group-ids <SG-ID>
- > aws ec2 authorize-security-group-ingress --group-id <SG-ID> --protocol tcp --port 22 --cidr <自分のIP>/32
- > aws ec2 revoke-security-group-ingress --group-id <SG-ID> --protocol tcp --port 22 --cidr <CIDR>

### 4.4 Systems Manager(踏み台なしのシェルアクセス)
- > aws ssm start-session --target <インスタンスID>          # SSHキー不要でシェル接続(要SSMエージェント+IAMロール)
- > aws ssm send-command --document-name "AWS-RunShellScript" --targets "Key=instanceids,Values=<ID>" --parameters 'commands=["uptime"]'
- > aws ssm get-parameter --name "/app/db/password" --with-decryption --query "Parameter.Value" --output text

### 4.5 IAM
- > aws iam list-users
- > aws iam list-roles
- > aws iam list-attached-role-policies --role-name <ロール名>
- > aws iam get-policy --policy-arn <ポリシーARN>
- > aws iam simulate-principal-policy --policy-source-arn <ARN> --action-names s3:GetObject --resource-arns <リソースARN>   # 権限のシミュレーション

### 4.6 Lambda
- > aws lambda list-functions --query "Functions[].FunctionName"
- > aws lambda invoke --function-name <関数名> --payload '{"key":"value"}' --cli-binary-format raw-in-base64-out out.json
- > aws lambda update-function-code --function-name <関数名> --zip-file fileb://function.zip
- > aws logs tail /aws/lambda/<関数名> --follow          # 実行ログをリアルタイム表示

### 4.7 CloudWatch Logs
- > aws logs describe-log-groups
- > aws logs tail <ロググループ名> --follow --since 1h
- > aws logs start-query --log-group-name <名前> --start-time <epoch> --end-time <epoch> --query-string 'fields @timestamp, @message | sort @timestamp desc | limit 20'

### 4.8 RDS
- > aws rds describe-db-instances --query "DBInstances[].{ID:DBInstanceIdentifier,Engine:Engine,Status:DBInstanceStatus,Endpoint:Endpoint.Address}" --output table
- > aws rds create-db-snapshot --db-instance-identifier <ID> --db-snapshot-identifier <スナップショット名>
- > aws rds stop-db-instance --db-instance-identifier <ID>     # 一時停止(最大7日、Auroraは除く)

### 4.9 ECR(コンテナレジストリ)
- > aws ecr get-login-password --region <リージョン> | docker login --username AWS --password-stdin <アカウントID>.dkr.ecr.<リージョン>.amazonaws.com
- > aws ecr create-repository --repository-name <リポジトリ名>
- > docker tag <イメージ>:<タグ> <アカウントID>.dkr.ecr.<リージョン>.amazonaws.com/<リポジトリ名>:<タグ>
- > docker push <アカウントID>.dkr.ecr.<リージョン>.amazonaws.com/<リポジトリ名>:<タグ>

### 4.10 コスト・アカウント確認
- > aws sts get-caller-identity                      # 現在のアカウントID・ARN
- > aws ce get-cost-and-usage --time-period Start=2026-08-01,End=2026-09-01 --granularity MONTHLY --metrics "UnblendedCost"
- > aws budgets describe-budgets --account-id <アカウントID>

### 4.11 --query(JMESPath)のよく使うパターン
- 配列から特定フィールドのみ: `--query "Reservations[].Instances[].InstanceId"`
- オブジェクトに整形: `--query "...[].{Name:Tags[?Key=='Name']|[0].Value, Id:InstanceId}"`
- 条件フィルタ: `--query "Functions[?Runtime=='python3.12'].FunctionName"`
- 件数: `--query "length(Functions)"`

## 5. ベストプラクティス
### 5.1 AWS Well-Architected Framework(6本の柱)
- 運用上の優秀性(Operational Excellence): 運用を自動化し、小さく頻繁に変更、失敗から学ぶ
- セキュリティ(Security): 全レイヤーで多層防御、最小権限、追跡可能性の確保
- 信頼性(Reliability): 障害を前提に設計、自動復旧、水平スケール、キャパシティ推測をやめる
- パフォーマンス効率(Performance Efficiency): 適切なリソース選定、需要に応じた調整、マネージドサービス活用
- コスト最適化(Cost Optimization): 消費モデルの採用、支出の可視化、不要リソースの停止・削除
- 持続可能性(Sustainability): 使用リソースの最小化、リージョン選定、マネージド化による効率向上

### 5.2 アカウント・組織
- ルートユーザーは初期設定(MFA有効化・請求設定)以外では使わない。日常作業はIAMユーザー/ロールで行う
- ルートユーザー・全IAMユーザーでMFAを必須にする
- 本番 / ステージング / 開発でアカウントを分離し、AWS Organizations + SCP(サービスコントロールポリシー)でガードレールを設ける
- 請求アラート・AWS Budgetsを設定し、想定外の課金を早期検知する
- CloudTrailを全リージョンで有効化し、ログを専用アカウントのS3に集約する

### 5.3 IAM・認証
- 最小権限の原則: 必要な権限のみ付与し、`*`(全許可)は避ける
- 人にはIAMユーザーの長期アクセスキーを配らず、IAM Identity Center(SSO)による一時的な認証情報を使う
- アプリ・EC2・Lambda・ECSにはアクセスキーを埋め込まず、IAMロール(インスタンスプロファイル / タスクロール)を割り当てる
- 外部システム連携はOIDC / IAMロール(`AssumeRoleWithWebIdentity`)を使い、長期キーの発行を避ける(例: GitHub ActionsのOIDC連携)
- アクセスキーが必要な場合も定期的にローテーションし、IAM Access Analyzer / Credential Reportで棚卸しする
- ポリシーはインラインではなく管理ポリシーで再利用し、権限境界(Permissions Boundary)で上限を制御する

### 5.4 ネットワーク
- VPCは用途別にサブネットを分け、DBやアプリはプライベートサブネットに置く。公開が必要なものだけパブリックサブネット + ALB経由にする
- Security Groupは「送信元をSGで指定」してリソース間の関係で許可する(CIDRべた書きを減らす)。SSH/RDPの全開放(`0.0.0.0/0`)は禁止
- 管理アクセスはSSM Session Manager経由にし、踏み台サーバー・22番ポート開放をなくす
- プライベートサブネットからAWS APIへはVPCエンドポイント(PrivateLink)を使い、NAT経由の通信・費用を削減する
- 通信はすべてTLS化する。ACMで証明書を無料発行・自動更新し、ALB/CloudFrontに紐付ける

### 5.5 データ保護
- 保管時の暗号化を既定で有効化(S3デフォルト暗号化、EBS暗号化のアカウント既定オン、RDS暗号化)
- S3はブロックパブリックアクセスをアカウント/バケット両方で有効化。公開配信はCloudFront + OAC(Origin Access Control)経由にする
- S3バケットはバージョニング + ライフサイクルポリシー(Glacier移行・期限切れ削除)を設定
- 認証情報・APIキーはコードやリポジトリに書かず、Secrets Manager / SSM Parameter Store(SecureString)で管理し、実行時に取得する
- バックアップはAWS Backupで一元化し、復元テストを定期的に行う。重要データはクロスリージョン/クロスアカウントにコピー

### 5.6 可用性・信頼性
- 本番は必ず複数AZに分散(EC2 Auto Scaling、RDS Multi-AZ、ALBのマルチAZ)
- 単一障害点(SPOF)を排除し、ステートはインスタンス外(RDS / DynamoDB / S3 / ElastiCache)に持たせてサーバーをステートレスにする
- Auto Scalingで需要変動に追従し、ヘルスチェック失敗インスタンスは自動入れ替え
- RTO/RPOを定義し、それに見合ったDR戦略(バックアップ&リストア / パイロットライト / ウォームスタンバイ / マルチサイト)を選ぶ
- 疎結合化: 同期呼び出しをSQS/EventBridge経由の非同期にしてスパイク吸収・障害分離する

### 5.7 コスト最適化
- 未使用リソースの削除: 停止中EC2にアタッチされたEBS、未アタッチのElastic IP、古いスナップショット、空のロードバランサー
- 定常的なワークロードはSavings Plans / リザーブドインスタンス、割り込み許容ワークロードはスポットインスタンスを活用
- 検証環境は業務時間外に自動停止(SSM Automation / スケジュール)
- S3ストレージクラスの最適化(Intelligent-Tiering、ライフサイクル)
- Cost Explorer・Budgets・Cost Anomaly Detectionで可視化し、タグ(`CostCenter` / `Project` / `Env`)でコスト配分を追跡
- CloudWatch Logsの保持期間を無期限にしない。適切な保持日数を設定する

### 5.8 監視・運用
- 主要メトリクス(CPU・メモリ・ディスク・エラー率・レイテンシ・キュー滞留)にCloudWatchアラームを設定し、SNS経由で通知
- ログは構造化(JSON)して集約し、CloudWatch Logs Insights / OpenSearchで検索可能にする
- 分散トレーシング(X-Ray / OpenTelemetry)でボトルネックを可視化
- パッチ適用はSSM Patch Managerで自動化。AMIは定期的に再作成(ゴールデンAMI)
- 復旧手順(Runbook)を文書化し、障害対応を訓練する

### 5.9 IaC・デプロイ
- 本番リソースはコンソール手動作成(ClickOps)を避け、CloudFormation / CDK / Terraformでコード管理する
- 環境差分はパラメータ/変数で吸収し、同一テンプレートを全環境に適用する
- CI/CDでlint・セキュリティスキャン(cfn-lint / checkov / tfsec)・plan差分レビューを挟む
- Terraformのstateはリモートバックエンド(S3 + DynamoDBロック)に置き、ローカル管理しない
- タグ付けを標準化し、テンプレート/モジュール側で強制する

## 6. よく使う設計パターン
### 6.1 静的サイトホスティング
- S3(非公開) + CloudFront(OAC) + ACM証明書 + Route 53。S3は直接公開しない

### 6.2 一般的なWeb 3層構成
- Route 53 → CloudFront → ALB(パブリックサブネット) → EC2/ECS(プライベートサブネット、Auto Scaling) → RDS Multi-AZ(プライベートサブネット)
- 認証情報はSecrets Manager、設定はSSM Parameter Store、静的アセットはS3+CloudFront

### 6.3 サーバーレスAPI
- API Gateway(またはLambda Function URL) → Lambda → DynamoDB
- 非同期処理はSQS/EventBridge + Lambda、長時間ワークフローはStep Functions

### 6.4 非同期・イベント駆動
- S3イベント / EventBridge → Lambda。負荷平準化やリトライにはSQS(+DLQ:デッドレターキュー)を挟む

## 7. トラブルシューティング
### 7.1 「Access Denied」「is not authorized to perform」
- 実行中のプリンシパルを確認: `aws sts get-caller-identity`
- IAMポリシー(アイデンティティベース)とリソースポリシー(S3バケットポリシー等)の両方、SCP、権限境界を確認
- `aws iam simulate-principal-policy`や、コンソールのIAM Policy Simulator / Access Analyzerで検証
- KMS暗号化リソースの場合、対象KMSキーへの`kms:Decrypt`権限も必要

### 7.2 リソースが見つからない / 一覧に出ない
- リージョンの取り違えがほとんど。`--region`または`AWS_DEFAULT_REGION`を確認
- プロファイル(アカウント)の取り違えも確認: `aws configure list`

### 7.3 EC2にSSH/接続できない
- Security Groupのインバウンドに自IPからの該当ポート許可があるか
- サブネットのルートテーブルにIGW(パブリック)またはNAT経由の経路があるか、Network ACLで拒否していないか
- パブリックIP / Elastic IPが付与されているか、インスタンスが`running`か
- 可能ならSSHをやめてSSM Session Manager接続に切り替える(SSMエージェント + インスタンスプロファイルにSSM権限が必要)

### 7.4 S3にアップロードしたファイルが403で見えない
- ブロックパブリックアクセスが有効(正常。公開はCloudFront+OAC経由にする)
- オブジェクト所有者とバケット所有者の不一致 → バケットの「オブジェクト所有者」設定を「バケット所有者強制」にする

### 7.5 想定外の高額請求
- Cost Explorerでサービス別・リージョン別に内訳を確認
- 典型例: NATゲートウェイのデータ処理料、クロスAZ/リージョン通信、放置されたRDS/Redshift、大量のCloudWatchカスタムメトリクス、S3リクエスト数
- Budgetsアラート・Cost Anomaly Detectionを設定して再発防止

### 7.6 スロットリング(`ThrottlingException` / `Rate exceeded`)
- API呼び出し過多。指数バックオフ + ジッターでリトライ(SDKは既定で実装済み、`max_attempts`を調整)
- ページネーションを適切に行い、不要なポーリングを減らす

## 8. 用語・注意点まとめ
- リージョンとAZ: リージョンは地理的なまとまり、AZはその中の独立データセンター群。冗長化は「複数AZ」が基本
- IAMロール vs ユーザー: ユーザーは人・恒久、ロールは一時的な権限の借用(EC2/Lambda/他アカウント/フェデレーション向け)
- Security Group vs Network ACL: SGはリソース単位・ステートフル・許可のみ、ACLはサブネット単位・ステートレス・許可/拒否
- マネージドサービス優先: 運用負荷・可用性・セキュリティパッチをAWSに任せられる。まずマネージドで検討する
- 削除系操作(`terminate-instances` / `rb --force` / `delete-*`)は復元不可能なものが多い。実行前に対象リソースIDとアカウント/リージョンを必ず確認する
- タグ付けは後回しにしない。`Name` / `Env` / `Project` / `Owner` / `CostCenter`を最初から統一ルールで付ける
- 「とりあえず作った」検証リソースは放置しない。作成時に削除予定を決め、可能ならIaCでまとめて破棄できるようにする
