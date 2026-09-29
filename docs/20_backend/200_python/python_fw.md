# Python主要フレームワーク概要・導入手順・利用用途ガイド
## 1. 目的・概要
### 1.1 本資料の目的
- Pythonの主要フレームワークについて、概要・導入手順・利用用途を整理し、選定時の指針とする
- 特にWebフレームワーク(Django/Flask/FastAPI)を中心に、周辺分野の主要フレームワークも合わせて記す

### 1.2 前提
- 導入手順は[pyenv-venv.md](./pyenv-venv.md)の手順で作成した仮想環境(`.venv`)内での実行を前提とする
  - > python -m venv .venv
  - > source .venv/bin/activate    # Windows(PowerShell)の場合: .venv\Scripts\Activate.ps1

### 1.3 Webフレームワーク比較表
| 項目 | Django | Flask | FastAPI |
|---|---|---|---|
| 分類 | フルスタック(Batteries included) | マイクロフレームワーク | マイクロフレームワーク(非同期特化) |
| 同期/非同期 | 同期(WSGI、ASGI対応も可) | 同期(WSGI) | 非同期(ASGI)、同期関数も混在可 |
| ORM | 標準搭載(Django ORM) | 標準搭載なし(SQLAlchemy等を別途導入) | 標準搭載なし(SQLAlchemy等を別途導入) |
| 管理画面 | 標準搭載(Django Admin) | なし | なし |
| 型ヒント活用 | 限定的 | 限定的 | 積極的に活用(バリデーション・補完に直結) |
| APIドキュメント自動生成 | なし(DRF等で別途対応) | なし(flask-smorest等で別途対応) | 標準搭載(Swagger UI/ReDoc) |
| 学習コスト | 中〜高(独自の作法が多い) | 低(素のPythonに近い) | 低〜中(型ヒントの理解が前提) |
| 主な用途 | 管理画面込みの業務システム、大規模Webサービス | 小〜中規模API、プロトタイプ、既存システムへの部分組込み | REST API、機械学習モデルのAPI化、高性能な非同期API |

## 2. Django
### 2.1 概要
- フルスタックのWebフレームワーク。ORM・管理画面(Admin)・認証・フォーム・テンプレートエンジン等、Webアプリに必要な機能一式を標準搭載する
- 「設定より規約(Convention over Configuration)」の思想が強く、プロジェクト構成やコーディング作法がフレームワーク側である程度定まっている
- MVT(Model-View-Template)アーキテクチャを採用(MVCのControllerがViewに、ViewがTemplateに相当)
- 参考資料
  - https://docs.djangoproject.com/ja/

### 2.2 導入手順
#### 2.2.1 インストール
- > pip install django

#### 2.2.2 プロジェクトの作成
- > django-admin startproject myproject
- > cd myproject

#### 2.2.3 アプリケーションの作成
- Djangoでは「プロジェクト」の中に機能単位の「アプリ」を複数作成する構成をとる
  - > python manage.py startapp myapp
- `myproject/settings.py`の`INSTALLED_APPS`に作成したアプリを追加
  ```python
  INSTALLED_APPS = [
      # ...
      "myapp",
  ]
  ```

#### 2.2.4 データベースのマイグレーション
- モデル定義(`myapp/models.py`)からマイグレーションファイルを生成・適用
  - > python manage.py makemigrations
  - > python manage.py migrate
- 既定ではSQLiteを使用(`settings.py`の`DATABASES`で変更可能)

#### 2.2.5 管理者ユーザーの作成(Admin利用時)
- > python manage.py createsuperuser

#### 2.2.6 開発サーバーの起動
- > python manage.py runserver
- ブラウザで http://127.0.0.1:8000/ ヘアクセスして起動確認
- 管理画面は http://127.0.0.1:8000/admin/ からアクセス

### 2.3 利用用途
- 管理画面(Admin)が必要な業務システム・社内ツール
- ECサイトやCMS等、認証・権限管理・フォーム処理が複雑な大規模Webサービス
- 「決まった型」で開発を進めたいチーム開発(規約が強く、実装のばらつきが出にくい)

### 2.4 主要な拡張機能
| ライブラリ | 用途 | 導入コマンド |
|---|---|---|
| Django REST Framework(DRF) | REST API構築(シリアライザ・認証・ページネーション等) | > pip install djangorestframework |
| django-allauth | 認証・ソーシャルログイン(Google/GitHub等) | > pip install django-allauth |
| django-cors-headers | CORS(クロスオリジン)対応 | > pip install django-cors-headers |
| django-environ | `.env`ファイルからの環境変数読み込み | > pip install django-environ |
| django-filter | クエリパラメータによる一覧のフィルタリング(DRFと併用) | > pip install django-filter |
| django-debug-toolbar | 開発時のSQLクエリ・実行時間等の可視化 | > pip install django-debug-toolbar |
| django-celery-beat / django-celery-results | Celeryの定期実行・実行結果のDB管理 | > pip install django-celery-beat |
| Django Channels | WebSocket等、ASGI経由の非同期・リアルタイム通信対応 | > pip install channels |
| Wagtail | Django上に構築されたCMS(コンテンツ管理システム) | > pip install wagtail |

## 3. Flask
### 3.1 概要
- 必要最小限の機能(ルーティング・テンプレートエンジン(Jinja2)・開発用サーバー)のみを提供するマイクロフレームワーク
- ORMや認証等の機能は標準搭載せず、必要に応じて拡張ライブラリ(Flask-SQLAlchemy、Flask-Login等)やサードパーティ製ライブラリを組み合わせて構成する
- 素のPythonに近い書き方ができ、自由度が高い分、設計方針はプロジェクト側で決める必要がある
- 参考資料
  - https://flask.palletsprojects.com/

### 3.2 導入手順
#### 3.2.1 インストール
- > pip install flask

#### 3.2.2 最小構成アプリの作成
- `app.py`を作成
  ```python
  from flask import Flask

  app = Flask(__name__)

  @app.route("/")
  def index():
      return "Hello, Flask!"

  if __name__ == "__main__":
      app.run(debug=True)
  ```

#### 3.2.3 開発サーバーの起動
- > python app.py
- または、Flask CLI経由で起動する場合
  - > export FLASK_APP=app.py            # Windows(PowerShell): $env:FLASK_APP="app.py"
  - > flask run --debug
- ブラウザで http://127.0.0.1:5000/ ヘアクセスして起動確認

### 3.3 利用用途
- 小〜中規模のWeb API・Webアプリケーション
- 既存システムへ部分的にWeb機能(管理用の簡易UI、Webhook受け口等)を組み込みたい場合
- 構成を自分で自由に決めたいプロトタイピング・検証用途

### 3.4 主要な拡張機能
| ライブラリ | 用途 | 導入コマンド |
|---|---|---|
| Flask-SQLAlchemy | ORM(SQLAlchemyのFlask向けラッパー) | > pip install flask-sqlalchemy |
| Flask-Migrate | DBマイグレーション(Alembicのラッパー) | > pip install flask-migrate |
| Flask-Login | 認証・セッション管理(ログイン状態の保持) | > pip install flask-login |
| Flask-WTF | フォーム処理・CSRF対策(WTFormsのFlask向けラッパー) | > pip install flask-wtf |
| Flask-CORS | CORS(クロスオリジン)対応 | > pip install flask-cors |
| Flask-RESTful / flask-smorest | REST API構築の補助(ルーティング・バリデーション・APIドキュメント生成等) | > pip install flask-smorest |
| Flask-JWT-Extended | JWTを用いたトークン認証 | > pip install flask-jwt-extended |
| Flask-Mail | メール送信 | > pip install flask-mail |
| Flask-Caching | レスポンス・処理結果のキャッシュ | > pip install flask-caching |
| Flask-Admin | 管理画面(Django Adminに近い機能)の追加 | > pip install flask-admin |

## 4. FastAPI
### 4.1 概要
- 型ヒント(Type Hints)を活用した、非同期(ASGI)対応のAPI向けフレームワーク
- Pythonの型ヒントからリクエスト/レスポンスのバリデーション(Pydantic)とAPIドキュメント(OpenAPI)を自動生成する
- Starlette(ASGIフレームワーク)をベースに構築されており、非同期処理を活かした高いスループットが特徴
- 参考資料
  - https://fastapi.tiangolo.com/ja/

### 4.2 導入手順
#### 4.2.1 インストール
- > pip install fastapi
- ASGIサーバー(Uvicorn)も併せて導入
  - > pip install "uvicorn[standard]"

#### 4.2.2 最小構成アプリの作成
- `main.py`を作成
  ```python
  from fastapi import FastAPI

  app = FastAPI()

  @app.get("/")
  def index():
      return {"message": "Hello, FastAPI!"}

  @app.get("/items/{item_id}")
  def read_item(item_id: int, q: str | None = None):
      return {"item_id": item_id, "q": q}
  ```

#### 4.2.3 開発サーバーの起動
- > uvicorn main:app --reload
  - `main:app`: `main.py`内の`app`変数(FastAPIインスタンス)を指定
  - `--reload`: コード変更時の自動再起動(開発時のみ推奨)
- ブラウザで http://127.0.0.1:8000/ ヘアクセスして起動確認
- APIドキュメント(自動生成)
  - Swagger UI: http://127.0.0.1:8000/docs
  - ReDoc: http://127.0.0.1:8000/redoc

### 4.3 利用用途
- REST API・マイクロサービスのバックエンド
- 機械学習モデルの推論APIとしての公開(型安全なリクエスト/レスポンス定義と相性が良い)
- 大量の同時接続や外部API呼び出し待ちが多い、非同期処理が有利なサービス

### 4.4 主要な拡張機能
| ライブラリ | 用途 | 導入コマンド |
|---|---|---|
| SQLModel | Pydantic+SQLAlchemyを統合したORM(FastAPI作者による、型ヒントとの親和性が高い) | > pip install sqlmodel |
| Pydantic Settings | `.env`ファイル・環境変数からの設定値読み込み(バリデーション付き) | > pip install pydantic-settings |
| FastAPI Users | 認証・ユーザー登録・パスワードリセット等のユーザー管理一式 | > pip install fastapi-users |
| python-multipart | フォームデータ・ファイルアップロードの処理(`UploadFile`利用時に必須) | > pip install python-multipart |
| fastapi-cache2 | レスポンスキャッシュ(Redis等をバックエンドに指定可能) | > pip install fastapi-cache2 |
| fastapi-pagination | 一覧APIのページネーション処理 | > pip install fastapi-pagination |
| httpx | 非同期対応のHTTPクライアント(外部API呼び出し・テストクライアントとしても使用) | > pip install httpx |
| Celery / arq | 重い処理の非同期タスクキュー(Celeryは6.2節参照、arqはasyncio前提の軽量な代替) | > pip install celery |

## 5. Webフレームワークの使い分けの目安
- 管理画面・認証・ORMまで一式そろった「枠組み」に乗って開発したい → Django
- 必要な機能だけを自分で組み合わせ、小さく始めたい・自由度を重視したい → Flask
- 型ヒントを活かした堅牢なAPIを書きたい、非同期処理やAPIドキュメント自動生成を重視したい → FastAPI
- 3者は排他的ではなく、例えば「管理画面はDjango、外部公開APIはFastAPI」のように用途別に併用するケースもある

## 6. その他の分野別主要フレームワーク
### 6.1 データ可視化・簡易Webアプリ: Streamlit
- 概要: Pythonスクリプトを書くだけで、データ分析結果や機械学習モデルの動作確認用UIを手軽にWebアプリ化できるフレームワーク
- 導入
  - > pip install streamlit
  - > streamlit run app.py
- 利用用途: 社内向けのデータ分析ダッシュボード、機械学習モデルのデモ・検証用UI

### 6.2 非同期タスクキュー: Celery
- 概要: 時間のかかる処理(メール送信、画像処理、バッチ処理等)をWebリクエストの応答から切り離し、非同期・分散実行するためのタスクキュー
- Django/Flask等のWebフレームワークと組み合わせて使うことが多い(単体のWebフレームワークではない)
- 導入
  - > pip install celery
  - メッセージブローカー(Redis等)が別途必要
  - > pip install redis
- 利用用途: 重い処理のバックグラウンド実行、定期実行バッチ(Celery Beat)

### 6.3 テストフレームワーク: pytest
- 概要: Python標準の`unittest`より簡潔な記法でテストを書ける、事実上の標準テストフレームワーク
- 導入
  - > pip install pytest
  - > pytest    # `test_*.py`または`*_test.py`を自動検出して実行
- 利用用途: 単体テスト・結合テスト全般。フィクスチャ(`fixture`)によるテスト前後処理の共通化、`parametrize`によるパラメータ化テストが強み

### 6.4 ORM単体利用: SQLAlchemy
- 概要: Python向けの代表的なORM(Object-Relational Mapper)兼SQLツールキット。Flask/FastAPI等、標準ORMを持たないフレームワークと組み合わせて使う
- 導入
  - > pip install sqlalchemy
- 利用用途: Flask/FastAPIでのデータベース操作、DjangoのORMを使わず既存DBに合わせて柔軟にスキーマ定義したい場合

## 7. 用語・注意点まとめ
- WSGI(Web Server Gateway Interface): 同期的なPython Webアプリケーションとサーバー間の標準インターフェース(Django/Flaskの標準はこちら)
- ASGI(Asynchronous Server Gateway Interface): WSGIを非同期対応に拡張したインターフェース(FastAPIの標準、DjangoもChannels等で対応可能)
- Uvicorn/Gunicorn: ASGI/WSGIアプリケーションを実際に動かすアプリケーションサーバー。開発時は各フレームワーク付属の開発用サーバーで十分だが、本番運用では別途導入する
- 開発用サーバー(`runserver`/`flask run`/`uvicorn --reload`)はいずれも本番運用向けではない旨が公式ドキュメントに明記されており、本番環境ではGunicorn/Uvicorn(+Nginx等のリバースプロキシ)を用いるのが一般的
- フレームワークとライブラリの違い: フレームワークは「アプリの骨格」を提供し開発者はその上に処理を追加していく(制御の反転)のに対し、ライブラリは開発者が主体でコードから呼び出して使う点が異なる
