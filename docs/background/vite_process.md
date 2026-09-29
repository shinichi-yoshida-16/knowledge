# Vite操作手順

## 1. 目的・概要
### 1.1 本資料の目的
- Viteの概要・導入手順・設定手順・利用方法を忘備録として記す

### 1.2 Viteの概要
- Viteはフロントエンド向けのビルドツール
  - 開発時: ネイティブESM(ES Modules)を利用し、ブラウザが直接モジュールをimportする形で配信するため、起動・HMR(Hot Module Replacement)が高速
  - 本番ビルド時: 内部でRollupを使いバンドル・最小化を行う
- 従来型バンドラ(webpack等)との違い
  - webpackは起動時にアプリ全体を事前バンドルするため、規模が大きくなるほど起動が遅くなる
  - Viteは変更されたモジュールのみをオンデマンドで変換・配信するため、規模に関わらず起動・更新が速い
- 主な特徴
  - 高速な開発サーバ起動、高速なHMR
  - TypeScript、JSX、CSS(Sass/Less等)を標準でサポート(型チェック自体は行わない)
  - React、Vue、Svelte等の主要フレームワーク向けテンプレートを標準提供
  - プラグイン機構(Rollupプラグイン互換)による拡張が可能
  - `vite.config.js`(または`.ts`)による設定の一元管理
- 参考資料
  - https://ja.vite.dev/guide/
  - https://ja.vite.dev/config/

## 2. 導入手順
### 2.1 前提条件
- Node.js
  - v20.19+ または v22.12+ (Vite 6系の場合。詳細は公式ドキュメントの対応バージョンを参照)
- パッケージマネージャ
  - npm、yarn、pnpm のいずれか(本資料はnpmを例に記載)

### 2.2 プロジェクトの新規作成
- 対話形式でテンプレートを選択して作成する場合
  - > npm create vite@latest
  - プロジェクト名、フレームワーク(React/Vue/Svelte/Vanilla等)、バリアント(TypeScript/JavaScript)を対話形式で選択
- 非対話形式で作成する場合(例: React + TypeScript)
  - > npm create vite@latest my-app -- --template react-ts
- 作成後の初期セットアップ
  - > cd my-app
  - > npm install

### 2.3 既存プロジェクトへの導入
- 依存関係としてViteを追加
  - > npm install -D vite
- フレームワークを利用する場合は対応プラグインも合わせて追加
  - > npm install -D @vitejs/plugin-react       # Reactの場合
  - > npm install -D @vitejs/plugin-vue         # Vueの場合
- プロジェクトルートに`index.html`を配置し、エントリポイントのscriptタグ(`<script type="module" src="/src/main.tsx"></script>`等)を記述
- `package.json`にスクリプトを追加
  - `"dev": "vite"`, `"build": "vite build"`, `"preview": "vite preview"`

### 2.4 導入確認
- > npx vite --version
- > npm run dev
- ブラウザで表示されたURL(既定は http://localhost:5173 )を開き、画面が表示されることを確認

## 3. 設定手順
### 3.1 設定ファイルの基本
- プロジェクトルートに`vite.config.js`(または`vite.config.ts`)を作成
- 基本形

```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
```

### 3.2 主な設定項目
- `plugins`
  - フレームワーク対応プラグインや各種Viteプラグインを配列で指定
- `server`
  - `server.port`: 開発サーバのポート番号(既定5173)
  - `server.host`: `true`にするとLAN内の他端末からもアクセス可能
  - `server.proxy`: バックエンドAPIへのプロキシ設定(CORS回避)
- `build`
  - `build.outDir`: ビルド成果物の出力先(既定`dist`)
  - `build.sourcemap`: ソースマップ出力の有無
  - `build.target`: トランスパイル先のブラウザ/ES対象
- `resolve.alias`
  - importパスのエイリアス設定(例: `@` → `src`)
- `base`
  - デプロイ先がサブディレクトリの場合の公開ベースパス
- `envPrefix` / `.env`ファイル
  - `.env`、`.env.local`、`.env.production`等で環境変数を管理
  - クライアント側コードから参照可能なのは`VITE_`プレフィックス付きの変数のみ(`import.meta.env.VITE_XXX`)
  - `.env.local`は`.gitignore`に含め、秘匿情報はコミットしない

### 3.3 TypeScript設定
- テンプレート作成時に`tsconfig.json`が自動生成される
- Viteはトランスパイルのみ行い型チェックは行わないため、型エラー検出には別途以下を利用
  - > npm run build (テンプレート標準の`build`スクリプトは`tsc -b && vite build`等で型チェックを含む場合が多い)
  - エディタ上でのリアルタイムチェックはIDEのTypeScript機能に依存

## 4. 利用方法
### 4.1 開発サーバの起動
- > npm run dev
- ファイル保存時にHMRで即座に画面へ反映される
- 終了は `Ctrl + C`

### 4.2 本番ビルド
- > npm run build
- `dist`ディレクトリ(既定)に静的ファイル一式が出力される
- ビルド成果物をローカルで確認する場合
  - > npm run preview
  - 本番相当の静的配信をローカルで簡易確認できる(開発サーバではない)

### 4.3 デプロイ
- `dist`配下の静的ファイルを、Vercel/Netlify/GitHub Pages等の静的ホスティングサービスへアップロードすれば配信可能
- Vercel等Git連携型のサービスでは、ビルドコマンド`npm run build`・出力ディレクトリ`dist`を指定することで自動デプロイ可能

### 4.4 プラグインの追加例
- 代表的なプラグイン
  - `@vitejs/plugin-react` / `@vitejs/plugin-vue`: 各フレームワーク対応
  - `vite-plugin-svgr`: SVGをReactコンポーネントとしてimport
  - `vite-tsconfig-paths`: `tsconfig.json`の`paths`設定をViteのエイリアスに反映
- 追加手順
  - > npm install -D <プラグイン名>
  - `vite.config.ts`の`plugins`配列に追加

### 4.5 よくあるコマンド
- > npm create vite@latest    # 新規プロジェクト作成
- > npm run dev               # 開発サーバ起動
- > npm run build             # 本番ビルド
- > npm run preview           # ビルド成果物のローカル確認
- > npx vite --version        # バージョン確認
- > npx vite --help           # CLIヘルプ表示
