# コーディング規約
## Lint／Formatter
- Linter
  - TBD
- Formatter
  - TBD
- 設定ファイル
  - TBD

## 使用言語毎の規約
### e.g. Typescript
- strictモード
  - 有効にする
- export
  - named exportとして、default exportは禁止とする
- 型定義
  - interfaceよりもtypeを優先する
- any
  - 禁止
- nullチェック
  - optional chaining(?.) と nullish coalescing(??) を使用する

## 命名規則
### e.g. Typescript
- ファイル名
  - kebab-case(e.g. user-profile.ts)
- コンポーネント
  - PascalCase(e.g. UserProfile.ts)
- 変数／関数
  - camelCase
- 定数
  - UPPER_SNAKE_CASE
- 型／インターフェイス
  - PascalCase

## インポート手順
- TBD

## コメント規約
- 日本語でコメントを記載する
- 人間が流れを追いやすいよう、適切にコメントを記載する
  - 自明な処理にはコメント不要とする
- JSDoc、JavaDoc等のドキュメントは必ず記載する

## エラーハンドリング
- TBD
