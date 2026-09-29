# pyenvとvenvの概要・使い分けガイド
## 1. 目的・概要
### 1.1 本資料の目的
- pyenvとvenvそれぞれの役割・違いを整理し、使い分けの指針とする
- 導入手順・日常の利用パターンを忘備録としてまとめる

### 1.2 pyenvの概要
- Pythonの「バージョン」自体を複数インストールし、プロジェクトやシェルごとに切り替えるためのツール
- OS標準のPythonには手を加えず、ユーザー領域に任意バージョンのPythonをビルド・インストールする
- 主な機能
  - 複数バージョンのPython(3.9, 3.10, 3.12等)を共存インストール
  - グローバル/ローカル(ディレクトリ単位)/シェル単位で使用バージョンを切り替え
  - `.python-version`ファイルによるディレクトリ単位の自動切り替え
- 参考資料
  - https://github.com/pyenv/pyenv

### 1.3 venvの概要
- Python 3.3以降に標準搭載されている、「仮想環境」を作成するための標準ライブラリ(モジュール)
- 1つのPythonバージョンに対して、プロジェクトごとに独立したパッケージ(ライブラリ)のインストール領域を作る
- 主な機能
  - プロジェクトごとに独立した`site-packages`(pipでインストールしたライブラリの置き場)を用意
  - グローバル環境やシステムのPython環境を汚さずに依存関係を管理
  - `venv`ディレクトリ配下に環境一式が作成される(ディレクトリを削除すればまっさらな状態に戻せる)
- 参考資料
  - https://docs.python.org/ja/3/library/venv.html

### 1.4 pyenvとvenvの違い
| 項目 | pyenv | venv |
|---|---|---|
| 管理対象 | Pythonインタプリタ本体(バージョン) | パッケージ・ライブラリのインストール領域 |
| 目的 | 複数のPythonバージョンを共存・切替 | プロジェクトごとに依存関係を分離 |
| 管理単位 | マシン全体/ディレクトリ/シェル | プロジェクト(ディレクトリ)単位 |
| 提供形態 | サードパーティ製ツール(別途インストールが必要) | Python標準ライブラリ(追加インストール不要) |
| 主な操作 | `pyenv install`, `pyenv global`, `pyenv local` | `python -m venv`, `activate`, `deactivate` |
| 併用可否 | venvと併用可能(むしろ併用が一般的) | pyenvと併用可能 |

- 両者は競合するものではなく、階層が異なる
  - pyenv: 「どのPythonバージョンを使うか」を解決する層
  - venv: 「そのバージョン上でどのライブラリ構成を使うか」を解決する層

## 2. 使い分け・利用パターン
### 2.1 基本方針
- 「どのPythonバージョンを使うか」→ pyenvで解決
- 「どのライブラリ構成を使うか」→ venvで解決
- 実務ではpyenv + venvを組み合わせて使うのが一般的なパターン

### 2.2 よくある利用パターン
- パターンA: pyenvでバージョン切替のみ行い、仮想環境はvenvで作成(本資料で推奨)
  - > pyenv local 3.12.4
  - > python -m venv .venv
- パターンB: pyenv-virtualenv(pyenvの公式プラグイン)で、バージョン管理と仮想環境管理を一体化
  - venvと機能は近いが、pyenvのサブコマンドとして仮想環境の作成・切替(`pyenv activate`等)まで行える
  - > pyenv virtualenv 3.12.4 myproject-3.12.4
  - > pyenv local myproject-3.12.4
- パターンC: pyenvを使わず、システム標準のPython + venvのみ
  - 複数バージョンの共存が不要な場合(シンプルな用途、CI環境等)に向く

### 2.3 使い分けの目安
- 複数プロジェクトで異なるPythonバージョンを行き来する → pyenv導入
- バージョンは1つで固定、ライブラリ構成だけ分離したい → venvのみで十分
- Docker等コンテナ単位で環境を分離している → コンテナが分離を担うため、pyenv/venv自体が不要なケースも多い

## 3. 導入手順
### 3.1 pyenvの導入(Linux/macOS/WSL)
#### 3.1.1 前提パッケージ
- ビルドに必要な依存パッケージを事前インストール(Ubuntu/Debianの例)
  - > sudo apt update
  - > sudo apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

#### 3.1.2 インストール
- 公式インストーラを使用
  - > curl https://pyenv.run | bash
- シェルの設定ファイル(`~/.bashrc`や`~/.zshrc`等)にPATH設定を追加
  ```bash
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  ```
- 設定反映
  - > exec "$SHELL"

#### 3.1.3 インストール確認
- > pyenv --version

### 3.2 pyenvの導入(Windowsネイティブ/pyenv-win)
- WSL2を利用している場合は3.1の手順(Linux向け)を推奨
- Windowsネイティブ環境で使う場合はpyenv-winを使用
  - > git clone https://github.com/pyenv-win/pyenv-win.git "$HOME/.pyenv"
  - 環境変数`PYENV`/`PYENV_HOME`/`PATH`の設定が必要(PowerShellの例)
  - > [System.Environment]::SetEnvironmentVariable('PYENV', $env:USERPROFILE + "\.pyenv\pyenv-win\", "User")
  - 参考資料: https://github.com/pyenv-win/pyenv-win

### 3.3 venvの導入
- Python 3.3以降であれば標準搭載のため追加インストール不要
- Python自体が未導入の場合は、先にpyenv等でPythonをインストールする(4.1節参照)
- インストール確認
  - > python --version
  - > python -m venv --help

## 4. 日常操作フロー
### 4.1 pyenvでのPythonバージョン管理
- インストール可能なバージョン一覧確認
  - > pyenv install --list
- バージョンのインストール
  - > pyenv install 3.12.4
- インストール済みバージョン一覧
  - > pyenv versions
- グローバル(既定)バージョンの設定
  - > pyenv global 3.12.4
- ディレクトリ単位のバージョン設定(`.python-version`ファイルが作成される)
  - > pyenv local 3.12.4
- シェル単位(現在のターミナルセッションのみ)のバージョン設定
  - > pyenv shell 3.12.4
- 現在有効なバージョン・優先順位の確認
  - > pyenv version
  - > pyenv versions

### 4.2 venvでの仮想環境管理
- 仮想環境の作成(`.venv`という名前が慣例)
  - > python -m venv .venv
- 仮想環境の有効化(activate)
  - Linux/macOS/WSL: > source .venv/bin/activate
  - Windows(PowerShell): > .venv\Scripts\Activate.ps1
  - Windows(コマンドプロンプト): > .venv\Scripts\activate.bat
  - 有効化中はプロンプトの先頭に`(.venv)`が付く
- パッケージのインストール(仮想環境内に閉じる)
  - > pip install <パッケージ名>
- 仮想環境の無効化
  - > deactivate
- 仮想環境の削除(ディレクトリを削除するだけでよい)
  - Linux/macOS/WSL: > rm -rf .venv
  - Windows(PowerShell): > Remove-Item -Recurse -Force .venv

### 4.3 pyenv + venvの組み合わせフロー(推奨パターン)
1. プロジェクトディレクトリでpyenvにより使用するPythonバージョンを固定
   - > pyenv local 3.12.4
2. そのバージョンのpythonでvenv環境を作成
   - > python -m venv .venv
3. venvを有効化
   - > source .venv/bin/activate
4. 依存パッケージをインストール
   - > pip install -r requirements.txt
5. 依存関係の固定(必要に応じて)
   - > pip freeze > requirements.txt

### 4.4 依存パッケージの記録・共有
- > pip freeze > requirements.txt      # 現在の環境の依存関係を書き出し
- > pip install -r requirements.txt    # 記録した依存関係を別環境に再現

## 5. トラブルシューティング
### 5.1 `pyenv install`でビルドが失敗する
- 前提パッケージ(3.1.1)が不足している場合が多い。エラーメッセージ中のライブラリ名を確認し、apt等で追加インストール
- ビルドログの詳細確認
  - > pyenv install -v 3.12.4

### 5.2 `pyenv global`でバージョンを切り替えたのに反映されない
- シェルの初期化設定(`eval "$(pyenv init -)"`等)が読み込まれていない可能性
  - > exec "$SHELL"       # シェルを再起動して設定を反映
- 実際に参照されているPythonのパスを確認
  - > which python
  - `~/.pyenv/shims/python`を指していない場合、PATH設定を見直す

### 5.3 venvを有効化してもグローバルのパッケージが見えてしまう
- 仮想環境が正しく有効化されているか確認(プロンプトに`(.venv)`が付いているか)
  - > which python    # .venv配下のpythonを指しているか確認
- 作成時に`--system-site-packages`オプションを付けていないか確認(グローバルのsite-packagesを引き継ぐオプション)

### 5.4 Windows(PowerShell)でactivateスクリプトが実行できない
- 実行ポリシーによりスクリプト実行がブロックされている場合がある
  - > Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  - 上記はそのPowerShellセッション限りの一時的な変更

## 6. 用語・注意点まとめ
- shim(シム): pyenvが`PATH`上に配置する仲介スクリプト。`python`等のコマンド実行時にshimが割り込み、設定に応じた実際のバージョンへ処理を振り分ける仕組み
- `.python-version`: `pyenv local`実行時にディレクトリ直下へ作成されるバージョン指定ファイル。リポジトリにコミットしてチームでバージョンを揃える用途にも使える
- venvで作成した仮想環境ディレクトリ(`.venv`等)は、リポジトリにコミットせず`.gitignore`に含めるのが一般的
- 仮想環境ディレクトリはファイルの集合にすぎず、有効化中でも中身を削除すると環境が壊れる点に注意
- pyenv-virtualenvはpyenvの公式プラグインで、venvと同様の仮想環境作成機能をpyenvのサブコマンドに統合したもの。venvと機能が重複するため、どちらか一方に統一して運用するのが望ましい
