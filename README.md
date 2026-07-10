# Codex Auto Router

GPT-5.6のSol・Terra・LunaとGPT-5.3-Codex-Sparkを、Codexの**名前付きCustom Agent**として自動で使い分けるルータープラグインです。

Codex Appでは、サブエージェントがそれぞれ「agent thread」として表示されます。Auto Routerは、親のSolまたはTerraからモデル固定済みCustom Agentを起動し、親が具体的な委譲指示、レビュー、統合、最終回答を担当します。

```text
@Auto Router developブランチを横断的に分析して、重要度別にIssue候補を抽出してください。変更はしないでください。
```

ユーザーが毎回、Agent名、モデル、フォールバック、担当範囲、受入条件、並列数、worktree、レビュー手順を書く必要はありません。

## 親が生成する指示は具体的なDelegation Brief

Auto Routerは、子Agentへ「認証を調べて」「このIssueを直して」のような曖昧な指示を送りません。

親のSol/Terraは、事前に必要なリポジトリ情報を確認し、各Agentへ**Delegation Brief v1**を生成します。

必須内容:

- 一意なworkstream ID
- 正確なCustom Agent名と期待モデル
- 1つの観測可能な目的
- ユーザー要件、base ref、Issue、ログなどのsource of truth
- 確認済みの事実と検証対象の仮説
- 依存関係、実行順、親の待機ルール
- 担当パス、シンボル、探索可能範囲
- 明確な除外範囲と親が保持する判断
- 読み取り・検証・書き込み権限
- worktree、基準コミット、ブランチ
- 必須手順
- 成果物と出力形式
- 客観的な受入条件
- 検証コマンドと期待結果
- 各受入条件を証明する証拠
- 停止条件と失敗時ステータス
- 子Agent、Sparkフォールバックの規則
- 親レビュー用のhandoff

簡略例:

```text
CONTRACT_VERSION=1
WORKSTREAM_ID=auth-write-route-inventory
AGENT_NAME=spark_scanner
EXPECTED_MODEL=gpt-5.3-codex-spark
ROLE=scan

OBJECTIVE:
組織スコープの書き込みAPIを全件分類し、認可依存がない候補を証拠付きで一覧化する。

SOURCE_OF_TRUTH:
- Base ref: develop at <SHA>
- Route root: apps/backend/metis_backend/api/
- Write methods: POST, PUT, PATCH, DELETE

OWNED_SCOPE:
- Paths: apps/backend/metis_backend/api/**
- Selection rule: 書き込みHTTPメソッドを持つroute
- Discovery boundary: route定義と直接のhandler/dependencyまで

OUT_OF_SCOPE:
- admin専用route
- 修正案の実装
- 認可ポリシーの設計判断

DELIVERABLES:
- Columns: method, route, handler, auth dependency, evidence
- Sort: route, method
- Completeness: 全件

ACCEPTANCE_CRITERIA:
- [ ] 対象の全write routeが分類されている
- [ ] 各行にroute定義とhandlerの証拠がある
- [ ] aliasの重複が統合されている
```

親はAgent起動前に契約品質ゲートを実行し、目的・範囲・成果物・受入条件・証拠などが不足している場合は指示を作り直します。

子Agent側も契約を検証します。重要項目が欠けている場合は推測で補わず、`contract-invalid`として不足項目を親へ返します。

詳細テンプレート:

- `plugins/codex-auto-router/skills/auto-router/references/delegation-contracts.md`
- `plugins/codex-auto-router/skills/auto-router/references/orchestrator-prompting.md`

## オーケストレーション方針

親はmanagerとして会話と最終結果を保持します。

- 作業は独立した成果物・所有範囲・証拠境界で分割
- 1 workstreamにつき原則1 owner
- 独立作業だけを並列化
- 依存関係がある作業は順番またはウェーブ実行
- 親が全結果を待ってレビュー
- `accepted`のみ統合
- アーキテクチャ、公開仕様、セキュリティ判断、競合解消は親が保持

親は子Agentに親会話全体や大量の無関係なログを渡さず、必要な事実と正確な参照だけをbriefへ含めます。

## スキャン処理はSpark優先、Lunaフォールバック

検索、抽出、一覧化、分類、コンパクトなリポジトリマップなど、明確でテキスト中心のスキャン処理は、まず`gpt-5.3-codex-spark`固定の`spark_scanner`へ割り当てます。

次の場合だけ`gpt-5.6-luna`固定の`luna_scanner`へ切り替えます。

- Sparkが現在のアカウント、プラン、クライアント、セッションで利用できない
- `spark_scanner`が現在のセッションへ読み込まれていない
- 画像などテキスト以外の入力が必要
- 必要なコンテキストがSparkで安全に扱える範囲を超える
- Sparkの起動が失敗する
- unsupported model、access、preview capacity、rate limitなどのエラー
- Sparkを期待したのに別モデルが表示される

フォールバック時は理由と実際に使われたAgent・モデルを記録します。Sparkの部分結果とLunaの結果は黙って混ぜず、親が破棄・置換・独立証拠のいずれとして扱うかレビューします。

## 重要: プラグイン単体ではモデル固定されません

CodexのプラグインはSkillを配布できますが、Custom Agentを自動登録する仕組みではありません。

Custom Agentが読み込まれていない状態で汎用スレッドを作ると、子は親モデルを継承するかCodexの自動選択になります。親がSolなら子もSolになることがあります。

そのため、Marketplaceからプラグインを入れるだけでなく、Custom Agentsのインストールが必須です。必要な名前付きAgentが見つからない場合、汎用Agentへフォールバックしません。Sparkだけが利用できない場合は、名前付き`luna_scanner`へフォールバックします。

## インストール

### 1. Marketplaceとプラグインを追加

```bash
codex plugin marketplace add tarou-imokenpi/codex-auto-router
```

Codex AppのPluginsから **Auto Router** をインストールします。

### 2. Custom Agentsとネスト設定をインストール

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

インストーラーは次を行います。

- `~/.codex/agents/`へ6つのCustom Agent TOMLをコピー
- 既存ファイルをタイムスタンプ付きでバックアップ
- `~/.codex/config.toml`の`[agents] max_depth`を最低`2`に設定
- `max_threads`が未設定なら`6`を追加

### 3. Codex Appを再起動

Custom Agentの登録内容はセッション開始時に読み込まれるため、ChatGPTデスクトップアプリを完全終了して再起動するか、新しいCodexタスクを開始してください。

### 4. セットアップ確認

macOS / Linux:

```bash
bash ./scripts/verify-install.sh
```

Windows PowerShell:

```powershell
./scripts/verify-install.ps1
```

Sparkが実際に現在のアカウントで利用可能かは実行時に判定されます。

## Custom Agent一覧

| Custom Agent | 固定モデル | 推論 | 用途 |
|---|---|---|---|
| `terra_explorer` | `gpt-5.6-terra` | Medium | 横断調査、実行経路、影響範囲、原因分析 |
| `terra_reviewer` | `gpt-5.6-terra` | High | 正しさ、セキュリティ、回帰、互換性レビュー |
| `terra_worker` | `gpt-5.6-terra` | Medium | 担当範囲を限定した実装 |
| `spark_scanner` | `gpt-5.3-codex-spark` | Low | 優先スキャナー。高速な検索、抽出、一覧化、分類 |
| `luna_scanner` | `gpt-5.6-luna` | Low | Spark非対応時のスキャナーフォールバック |
| `luna_verifier` | `gpt-5.6-luna` | Medium | テスト、lint、型チェック、再現確認 |

すべてのTOMLで`model`を明示しています。

各Agentは指示を実行する前にDelegation Briefを検証します。

- Explorer: 症状、入口、探索境界、仮説、期待するtrace/map
- Reviewer: review対象、要件、risk lens、severity rubric、materiality
- Worker: 承認済み要件、所有範囲、互換性、worktree、tests
- Scanner: 検索規則、対象範囲、重複排除、並び順、出力列
- Verifier: 検証対象、環境、コマンド、期待結果、source修正禁止

## 親・Terra・Spark・Lunaの階層

```text
親 Sol / Terra（depth 0）
├─ terra_explorer / terra_reviewer / terra_worker（depth 1）
│  ├─ spark_scanner（depth 2、スキャンの第一候補）
│  ├─ luna_scanner（depth 2、Sparkフォールバック）
│  └─ luna_verifier（depth 2、検証）
├─ spark_scanner（depth 1）
├─ luna_scanner（depth 1）
└─ luna_verifier（depth 1）
```

Terraが子Agentを起動する場合も、子専用の完全なDelegation Briefを作成します。子の担当範囲はTerraの担当範囲の厳密な部分集合でなければなりません。

## モデル不一致時の扱い

親は起動前後にCustom Agent名と表示モデルを確認します。

次の場合は、そのスレッドを期待モデルの成果として採用しません。

- `default`、`worker`、`explorer`などの汎用Agentが起動
- Terraを期待したのにSol
- Sparkを期待したのに別モデル
- Lunaを期待したのに別モデル
- 必要なCustom Agentがセッションへ読み込まれていない

Sparkだけが失敗した場合は、理由を記録し、同等の目的・範囲・成果物・受入条件を持つ新しい`luna_scanner` briefを作成します。

## 大規模タスク

```text
@Auto Router スレッドを使って、このリポジトリ全体を領域別に監査し、根拠のあるIssue候補だけを統合してください。
```

親は最初に大規模タスクを次のように整理します。

1. 親レベルの完了条件を定義
2. base ref、repository instructions、重要な入口を確認
3. 成果物と所有境界でworkstreamを分割
4. 依存関係をDAGまたはウェーブとして整理
5. 各workstreamへ具体的なDelegation Briefを作成
6. 契約品質ゲートを通過したAgentだけ起動
7. 全結果を待って親レビュー
8. `accepted`だけを統合

## 競合する書き込みとGit worktree

複数の書き込みAgentが競合する可能性がある場合、親が専用ブランチと専用`git worktree`を作成します。

```bash
git worktree add \
  -b codex/auto-router/<workstream> \
  ../.codex-worktrees/<workstream> \
  <base-commit>
```

worktree分離が必須になる例:

- 2つ以上のAgentがファイルを変更
- 担当範囲が重なる可能性
- lockfile、設定、スキーマ、マイグレーション、生成コードを変更
- ある変更が別AgentのAPIや型へ影響
- 編集所有権を事前に完全分離できない

各Terra Workerは指定worktree、ブランチ、基準コミットを確認し、担当変更だけをコミットします。Agent同士はmerge/rebaseせず、親がレビュー後に統合します。

## スレッド完了後の親レビュー

`complete`は自動承認を意味しません。

親は各スレッドについて次を確認します。

1. 期待したCustom Agent名とモデル
2. 元の具体的なbrief、依存関係、担当範囲、除外範囲
3. 成果物が指定したschemaに一致
4. すべての受入条件に証拠がある
5. Sparkフォールバック理由
6. 実装のbase commit、worktree、branch、commit、diff、dirty状態
7. テスト結果と互換性
8. 他スレッドとの重複、矛盾、競合

判断:

| 判断 | 扱い |
|---|---|
| `accepted` | 統合・最終回答に利用可能 |
| `revision-required` | 具体的な修正briefを発行して再レビュー |
| `rejected` | 統合しない |

親自身の承認判断は別Agentへ委譲しません。

## 更新

```bash
codex plugin marketplace upgrade tarou-imokenpi-plugins
git pull
bash ./scripts/install-agents.sh
bash ./scripts/verify-install.sh
```

更新後はCodex Appを再起動してください。

## トラブルシューティング

### 子Agentが`contract-invalid`を返す

親の指示に目的、範囲、成果物、受入条件、証拠、依存関係、権限などが不足しています。Auto Routerは不足情報を確認し、briefを修正してから再実行します。

### Sparkが起動できない

SparkはChatGPT Pro向けResearch Previewで、利用状況や容量によりアクセスできない場合があります。`luna_scanner`へフォールバックし、実際のモデルを親が確認します。

### 子スレッドがSolになる

原因候補:

- Custom Agentsをインストールしていない
- インストール後にCodex Appを再起動していない
- 古いSkillが汎用Agentを起動
- Agent名が正確でない

```bash
git pull
bash ./scripts/install-agents.sh
bash ./scripts/verify-install.sh
```

その後、Codex Appを完全終了して再起動します。

### Terraが子Agentを起動できない

`~/.codex/config.toml`:

```toml
[agents]
max_depth = 2
```

## License

MIT License
