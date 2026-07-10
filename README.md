# Codex Auto Router

gpt5.6のSol,Terra,Lunaを自動で使い分けるモデルルータープラグインです。

親エージェントはSolまたはTerraを使い、依頼内容からスレッド分割、サブエージェントの要否、人数、モデル、役割、並列化、検証方法を自動判断します。毎回エージェント割り当てを書く必要はありません。

## 使い方

Codex Appで親モデルをSolまたはTerraにし、入力欄で`@`を押して**Auto Router**を選びます。

```text
@Auto Router developブランチを横断的に分析して、重要度別にIssue候補を抽出してください。変更はしないでください。
```

```text
@Auto Router この不具合の原因を調査して修正し、関連テストまで実行してください。
```

```text
@Auto Router スレッドを使って、この大量のIssue候補を領域別に検証し、重複を統合してください。
```

## スレッドとサブエージェントの自動選択

通常規模の作業は、現在の親スレッド内で必要最小限のTerra/Lunaサブエージェントを使います。

次の場合は、サブエージェントの同時実行上限へ詰め込まず、複数のCodexスレッドへ分割します。

- ユーザーがスレッド利用を明示した場合
- 独立した読み取り作業が4件を超える場合
- 独立した書き込み作業が2件を超える場合
- リポジトリ全体の監査、大規模移行、大量タスクなど、長い独立作業が多数ある場合

スレッドのモデル規則は固定です。

| 作成するスレッド | 用途 | スレッド内のサブエージェント |
|---|---|---|
| Terraスレッド | 判断、横断調査、レビュー、実装 | **Lunaのみ使用可能** |
| Lunaスレッド | 明確で機械的な独立タスク | **使用不可** |

- 親のSol/Terraだけがトップレベルの作業スレッドを作ります。
- Terraスレッドは、担当範囲内の検索・抽出・検証をLunaへ委譲できます。
- TerraスレッドはTerraサブエージェントや追加スレッドを作りません。
- Lunaスレッドは末端ワーカーであり、サブエージェントも追加スレッドも作りません。
- 同時スレッド数に上限がある場合は、作業境界を維持したまま複数の波に分けて実行します。
- 最終的な重複排除、設計判断、統合、検証は親が担当します。

## スレッド完了後の親レビュー

スレッドが`complete`を返しても、その結果は自動的には採用されません。**スレッド完了は親レビューの準備ができた状態**を意味します。

親のSol/Terraは、各スレッドの完了後に必ず次を確認します。

1. 元の依頼、担当範囲、除外範囲、完了条件との一致
2. 重要な主張を支えるファイル、シンボル、コマンド、ログなどの直接確認
3. 読み取り・レビュースレッドの重要度、確信度、根拠の妥当性
4. 実装スレッドの実際の差分、変更ファイル、担当範囲外の編集、互換性
5. テストや検証コマンドの実行結果。必要に応じて親が再実行
6. 他スレッドとの重複、矛盾、編集競合、古い前提の有無

親は各スレッドに対して、内部的に次のいずれかを判断します。

| 判断 | 扱い |
|---|---|
| `accepted` | 統合・最終回答への利用が可能 |
| `revision-required` | 修正依頼を出し、修正版を再レビュー |
| `rejected` | 統合せず、必要なら親または別の限定スレッドで対応 |

- 親自身によるレビューと承認は、別のスレッドやサブエージェントへ丸投げしません。
- 追加のReviewerを補助として使うことはできますが、最終的な採用判断は親が行います。
- `partial`、`blocked`、`revision-required`、`rejected`、または親レビュー未実施の結果は、完了済み成果として統合しません。
- 修正後の成果物も、もう一度親レビューを通します。
- 最終回答は、回答に影響する全スレッドのレビューが終わるまで生成しません。

## GitHub Marketplaceからインストール

Codex CLIでMarketplaceを追加します。

```bash
codex plugin marketplace add tarou-imokenpi/codex-auto-router
```

その後、Codex Appの**Plugins**またはCodex CLIの`/plugins`から**Auto Router**をインストールし、新しいタスクを開始してください。

プラグインだけでも自動ルーティングできます。モデルと役割をCustom Agent定義で固定したい場合は、次の追加インストールを一度だけ実行します。

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

親は、要件理解、分解、スレッド作成、親レビュー、設計判断、競合解消、統合、最終検証を担当します。子としてSolは起動しません。

## 権限の扱い

依頼文の動詞と明示条件から判断します。

- 「分析」「レビュー」「探す」「監査」: 読み取り専用
- 「実装」「修正」「更新」「リファクタ」: 変更あり
- 「テスト」「再現」「確認」: 検証中心
- 「調査して修正」: 調査 → 実装 → 検証

「変更しないでください」などの明示条件が最優先です。

## 構成

```text
.agents/plugins/marketplace.json       GitHub配布用Marketplace
plugins/codex-auto-router/             Codex Appプラグイン
  .codex-plugin/plugin.json
  skills/auto-router/SKILL.md
agents/                                任意のCustom Agent定義
profiles/                              Sol/Terra親のCLIプロファイル例
scripts/                               インストーラー
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
- スレッドやサブエージェントは単一実行より多くの利用量を消費します。Skillは最小限の構成を選びます。
- 利用可能なモデル、スレッド数、同時実行数、推論レベルは契約プランおよびCodexの提供状況に依存します。

## License

MIT License
