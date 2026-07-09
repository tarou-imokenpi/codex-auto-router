# Codex Auto Router

Codex Appで、**`@Auto Router`を選び、やってほしいことだけを書く**ためのプラグインです。

親エージェントはSolまたはTerraを使い、依頼内容からサブエージェントの要否、人数、役割、Terra/Lunaの割り当て、並列化、検証方法を自動判断します。毎回エージェント名や担当範囲を書く必要はありません。

## 使い方

Codex Appで親モデルをSolまたはTerraにし、入力欄で`@`を押して**Auto Router**を選びます。

```text
@Auto Router developブランチを横断的に分析して、重要度別にIssue候補を抽出してください。変更はしないでください。
```

```text
@Auto Router この不具合の原因を調査して修正し、関連テストまで実行してください。
```

```text
@Auto Router 現在のブランチをdevelopとの差分でレビューし、実害のある問題だけを報告してください。
```

## GitHub Marketplaceからインストール

Codex CLIでMarketplaceを追加します。

```bash
codex plugin marketplace add tarou-imokenpi/codex-auto-router
```

その後、Codex Appの**Plugins**またはCodex CLIの`/plugins`から**Auto Router**をインストールし、新しいタスクを開始してください。

プラグインだけでも、Skillが子モデルと役割を指定してサブエージェントを起動します。モデルと役割をCustom Agent定義で固定したい場合は、次の追加インストールを一度だけ実行します。

### Custom Agentsの追加インストール

macOS / Linux:

```bash
git clone https://github.com/tarou-imokenpi/codex-auto-router.git
cd codex-auto-router
bash ./scripts/install-agents.sh
```

Windows PowerShell:

```powershell
git clone https://github.com/tarou-imokenpi/codex-auto-router.git
cd codex-auto-router
./scripts/install-agents.ps1
```

## 自動ルーティング

| 論理ロール | モデル | 主な用途 |
|---|---|---|
| Luna Scanner | GPT-5.6 Luna / Low | 検索、一覧化、抽出、分類 |
| Luna Verifier | GPT-5.6 Luna / Medium | テスト、lint、型チェック、再現確認 |
| Terra Explorer | GPT-5.6 Terra / Medium | 複数ファイルの経路追跡、原因・影響分析 |
| Terra Reviewer | GPT-5.6 Terra / High | 正しさ、セキュリティ、回帰、互換性レビュー |
| Terra Worker | GPT-5.6 Terra / Medium | 所有範囲を限定した実装 |

親は、要件理解、分解、設計判断、競合解消、統合、最終検証を担当します。子としてSolは起動しません。

## Agent数の目安

- 小さな単一ファイル作業: 親だけ、または1体
- 通常の複数ファイル作業: 2〜3体
- リポジトリ全体の監査や大きな変更: 3〜4体
- 書き込みAgent: 原則1体。所有範囲を完全分離できる場合のみ最大2体

## 権限の扱い

依頼文の動詞と明示条件から判断します。

- 「分析」「レビュー」「探す」「監査」: 読み取り専用
- 「実装」「修正」「更新」「リファクタ」: 変更あり
- 「テスト」「再現」「確認」: 検証中心
- 「調査して修正」: 調査 → 実装 → 検証

「変更しないでください」などの明示条件が最優先です。実際のサブエージェント権限は、Codex Appの入力欄下で選んだ親ターンの権限モードにも従います。

## 構成

```text
.agents/plugins/marketplace.json       GitHub配布用Marketplace
plugins/codex-auto-router/             Codex Appプラグイン
  .codex-plugin/plugin.json
  skills/auto-router/SKILL.md
agents/                                任意のCustom Agent定義
profiles/                              Sol/Terra親のCLIプロファイル例
scripts/                               Custom Agentインストーラー
examples/                              最小プロンプト例
```

## 更新

```bash
codex plugin marketplace upgrade tarou-imokenpi-plugins
```

Custom Agentsを利用している場合は、更新後に次を再実行してください。同名ファイルはタイムスタンプ付きでバックアップされます。

```bash
bash ./scripts/install-agents.sh
```

## 注意

- 親モデル自体はプラグインから切り替えません。Codex App側でSolまたはTerraを選択してください。
- サブエージェントは単一実行より多くのトークンを消費します。Skillは最小限の人数を選ぶように設計されています。
- 利用可能なモデルと推論レベルは、契約プランおよびCodexの提供状況に依存します。

## License

MIT License
