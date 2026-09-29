# プロジェクト概要
## プロジェクト名
- TBD

## 目的(何を解決するプロダクトか)
- TBD

## 主要スタック( e.g. Typescript / Node.js v22 / MariaDB )
- TBD

## リポジトリ構成
- TBD

# コマンド一覧
- TBD

# 参照ドキュメント
- README.md
  - 開発環境セットアップ手順
- docs/
  - 要件・制約・設計・アーキテクチャ(設計の進捗で個別ファイルに更新する)
- CONTRIBUTING.md
  - Git規約・PR手順・レビュー基準

# Claudeへの指示
- コード変更前に、必ず既存の実装とテストを読む
- 実装の判断に迷ったら docs/ 以下の要件・制約ドキュメントを参照する
- セキュリティ関連の変更（認証・暗号化・権限）は必ずユーザーに確認する
- コミットメッセージは CONTRIBUTING.md の規約に従う
- TODO / FIXME は残さず Issue を立てるよう促す

# 制約／禁止事項
- .env ファイルの内容をログや出力に含めない
- TBD

# 既知の注意点
- TBD

# Claude 設定構成
- プロジェクト内で利用可能なClaudeの設定一覧
- 詳細は各ファイルを参照

## スキル(/skill_name で呼び出し)
| コマンド | ファイル | 概要 |
|---|---|---|
| TBD | TBD | 追加したら記載 |

## エージェント(@agent_name でメンション)
| エージェント | ファイル | 概要、移譲するとよい場面 |
|---|---|---|
| @code-reviewer | .claude/.agents/code-reviewer.md | 読み取り専用のコードレビュー |
| @test-writer | .claude/.agents/test-writer.md | テストコードの生成と補完 |
| TBD | TBD | 追加したら記載 |

## ルール(自動読込み)
| ファイル | 読込みタイミング | 内容 |
|---|---|---|
| .claude/.rules/coding-style.md | 常時 | コーディングスタイル、命名規則 |
| .claude/.rules/security.md | 常時 | セキュリティ規約 |
| .claude/.rules/testing.md | テストファイル操作時 | テスト規約、カバレッジ目標 |
| TBD | TBD | 追加したら記載 |
