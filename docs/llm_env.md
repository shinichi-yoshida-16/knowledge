# ローカルLLM環境構築手順書
## 1. 背景・目的
- オンプレミスのLLM環境構築手順を、自身の備忘録としてまとめる

## 2. 概要
- 目的
  - RTX3070(VRAM 8GB)環境で、コード生成及びIT調査用のローカルLLM環境を構築する
- 構成
  - WSL2(Ubuntu)、Ollama(推論エンジン)、Open WebUI(Python venv)
- 対象モデル
  - gpt-oss:20b
  - vram内に完全オフロード氏、高速に動作

## 3. 手順
### 3.1 事前準備(Windows & WSLLS2)
#### 3.1.1 NVIDIA CUDAドライバーの確認(Windows側)
- WindowsのPowerShellで以下を実行し、GPUおよびCUDA対応ドライバーが認識されていることを確認する。

````
nvidia-smi
---
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI XXX.XXX.XX             Driver Version: XXX.XX         CUDA Version: XX.X     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX XXXX ...    On  |   00000000:01:00.0 Off |                  N/A |
| N/A   XXX    XX             XXW /  XXXW |    XXXXMiB /   XXXXMiB |     XX%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
````

#### 3.1.2 WSL2(Ubuntu)のパッケージ更新と必要ツール導入
- WSL2(Ubuntu)を開き、システム更新と必須ツールをインストールする
````
# パッケージの更新
sudo apt update && sudo apt upgrade -y

# 必須ツールの導入（zstd, python3-pip, python3-venv 等）
sudo apt install -y zstd python3-pip python3-venv git build-essential

# WSL2側でのGPU認識確認
nvidia-smi
````

### 3.2. 推論エンジン(Ollama)のセットアップ
#### 3.2.1 Ollama のインストールと起動
- 以下インストールスクリプトを実行し、サービスを開始する
````
curl -fsSL https://ollama.com/install.sh | sh
````

#### 3.2.2 コード生成最適化モデルの取得
- コーディングおよびIT技術調査に適していると思われるモデルをダウンロードする

````
ollama pull gpt-oss:20b
````

#### 3.2.3 不要なモデルの削除
- 過去に取得した不要なモデルがあれば削除してストレージ容量を解放する
````
# 確認
ollama list

# 削除
ollama rm <削除するモデル>
````

### 3.3 UI環境(Open WebUI)の構築(Python直接導入)
- Dockerを利用せず、Pythonの仮想環境(venv)上に直接Open WebUIを構築する

#### 3.3.1 仮想環境の作成をパッケージのインストール
- 専用ディレクトリを作成し、仮想環境の作成とopen-webuiパッケージインストール
````
# ディレクトリ作成と移動
mkdir -p ~/open-webui
cd ~/open-webui

# Python仮想環境の作成と有効化
python3 -m venv venv
source venv/bin/activate

# インストール
pip install --upgrade pip
pip install open-webui
````

#### 3.3.2 Open WebUIの起動
- 起動コマンド
````
open-webui serve
````

- 起動後、ブラウザで以下URLにアクセスし、初回管理者アカウントを作成する
> http://localhost:8080

- 次回以降の起動コマンド
````
cd ~/open-webui && source venv/bin/activate && open-webui serve
````

### 3.4 コード生成精度の最適化設定
#### 3.4.1 システムプロンプトの設定(日本語化、役割固定)
- Open WebUIの管理者パネル > 設定 > モデル(又はカスタムモデル設定)から、使用するモデルに以下のシステムプロンプトを登録する
````
あなたは優秀なITエンジニアおよび技術リサーチャーです。
以下のルールを厳格に守って回答してください：
1. 原則としてすべての対話・解説・コード注釈は「日本語」で行ってください。
2. コード生成を求められた場合は、構文エラーのない保守性の高いコードを提示してください。
3. 技術的な解説は結論を最初に述べ、必要に応じて箇条書き等で簡潔に整理してください。
4. 回答には必ず一次情報を添え、回答根拠を示すようにしてください。
````

#### 3.4.2 コード生成向けのパラメータ設定例
- 精度を高め、構文エラーや春市ネーションを防ぐためのパラメータ値の例

| パラメータ | 推奨値 | 役割・影響 |
|---|---|---|
| Temperature| 0.2 | ランダム性を下げ、構文エラーや間違ったAPI作成を防ぐ |
| Top_P | 0.3 | 確実性の高い五位候補だけに絞り込む |
| Min_P | 0.05 | 低確率な不自然トークンをカットし、安全性を高める |
| Repeat Penalty | 1.05 | 無限ループを防ぎつつ、コードに必要な構文重複を許す |
| Num Ctx | 8192 | 長い文脈(コードベース)を読み込めるようコンテキスト長を拡張する |


### 3.5 (オプション)設定固定済みカスタムモデルの作成
- 3.4 パラメータとシステムプロンプトをあらかじめ組み込んだ専用モデルを Ollama 内に作成する

#### 3.5.1 作業ディレクトリ(~/open-webui)に Modelfile を作成する
````
FROM gpt-oss:20b

# パラメータ設定（推論精度向上）
PARAMETER temperature 0.4
PARAMETER top_p 0.3
PARAMETER min_p 0.05
PARAMETER repeat_penalty 1.05
PARAMETER num_ctx 16384

# システムプロンプト設定（日本語化・思考のルール）
SYSTEM """
あなたは優秀なITエンジニアおよび技術リサーチャーです。
以下のルールを厳格に守って回答してください：
1. 原則としてすべての対話、解説、コード注釈は「日本語」で行ってください。
2. コード生成を求められた場合は、構文エラーのない保守性の高いコードを提示してください。
3. 技術的な解説は結論を最初に述べ、必要に応じて箇条書き等で簡潔に整理してください。
4. 回答には必ず一次情報を添え、回答根拠を示すようにしてください。
"""
````


#### 3.5.2 カスタムモデルの作成・登録
````
ollama create gpt-oss-custom -f ./Modelfile_gpt_oss
````

- 作成・登録後、Open WebUI(又はCLI)から gpt-oss-custom を指定することで最適化設定が適用される

## 4. 運用と接続確認
1. Open WebUIを開く
  - > http://localhost:8080
2. モデル選択ドロップダウンから、gpt-oss-customを選択する
3. チャット欄からコード生成やIT調査の指示を入力し、応答が日本語で正しく生成されることを確認する

