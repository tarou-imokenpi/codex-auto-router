# Codex Auto Router

GPT-5.6のSol・Terra・Lunaを、Codexの**名前付きCustom Agent**として自動で使い分けるルータープラグインです。

Codex Appでは、サブエージェントがそれぞれ「agent thread」として表示されます。Auto Routerは、親のSolまたはTerraから、モデルを明示的に固定したTerra/Luna Custom Agentを起動します。

```text
@Auto Router developブランチを横断的に分析して、重要度別にIssue候補を抽出してください。変更はしないでください。
```

ユーザーが毎回、Agent名、モデル、並列数、worktree、レビュー手順を書く必要はありません。

## 重要: プラグイン単体ではモデル固定されません

CodexのプラグインはSkillを配布できますが、Custom Agentを自動登録する仕組みではありません。

Custom Agentが読み込まれていない状態で汎用スレッドを作ると、子は親のモデル設定を継承するかCodexの自動選択になります。親がSolなら、子スレッドもSolになることがあります。

そのため、**Marketplaceからプラグインを入れるだけでなく、Custom Agentsのインストールが必須**です。Auto Routerは、必要な名前付きAgentが見つからない場合、汎用Agentへフォールバックしません。

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

- `~/.codex/agents/`へ5つのCustom Agent TOMLをコピー
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

## 正しいスレッドの仕組み

Codexで表示されるスレッドは、親が起動したサブエージェントの実行スレッドです。

Auto Routerは「Terraを使って」と書いた汎用Agentを作るのではなく、次の正確なCustom Agent名を指定します。

| Custom Agent | 固定モデル | 推論 | 用途 |
|---|---|---|---|
| `terra_explorer` | `gpt-5.6-terra` | Medium | 横断調査、実行経路、影響範囲、原因分析 |
| `terra_reviewer` | `gpt-5.6-terra` | High | 正しさ、セキュリティ、回帰、互換性レビュー |
| `terra_worker` | `gpt-5.6-terra` | Medium | 担当範囲を限定した実装 |
| `luna_scanner` | `gpt-5.6-luna` | Low | 検索、抽出、一覧化、分類 |
| `luna_verifier` | `gpt-5.6-luna` | Medium | テスト、lint、型チェック、再現確認 |

Custom Agent TOMLで`model`を省略した場合は親設定を継承する可能性がありますが、このリポジトリの5 AgentはすべてモデルIDを明示しています。

## 親・Terra・Lunaの階層

```text
親 Sol / Terra（depth 0）
├─ terra_explorer / terra_reviewer / terra_worker（depth 1）
│  └─ luna_scanner / luna_verifier（depth 2、必要な場合のみ）
└─ luna_scanner / luna_verifier（depth 1）
```

ルール:

- 親はSolまたはTerra
- 親は正確な名前付きTerra/Luna Agentを直接起動可能
- Terraは契約で許可された場合のみ、名前付きLunaを起動可能
- TerraはSol、Terra、汎用Agentを子として起動しない
- Lunaは末端Agentであり、子Agentを起動しない
- Terra→Lunaには`agents.max_depth >= 2`が必要
- 同時スレッド上限を超える場合は複数ウェーブで実行

通常は親から必要なAgentを直接起動します。Terraが担当領域内の限定的な検索や検証を必要とする場合だけ、Lunaを孫Agentとして使用します。

## モデル不一致時の扱い

親は起動前後に、Custom Agent名と表示モデルを確認します。

次の場合は、そのスレッドをTerra/Lunaの成果として採用しません。

- `default`、`worker`、`explorer`などの汎用Agentが起動された
- Terraを期待したのにSolとして表示された
- Lunaを期待したのに別モデルとして表示された
- 必要なCustom Agentが現在のセッションに読み込まれていない

Agentが見つからない場合は、親だけで小さな作業を続けるか、セットアップ不足として停止します。Solスレッドへ黙ってフォールバックはしません。

## 大規模タスク

```text
@Auto Router スレッドを使って、このリポジトリ全体を領域別に監査し、根拠のあるIssue候補だけを統合してください。
```

Auto Routerは、領域ごとに正確な名前付きAgentを割り当てます。

- 判断や横断分析: Terra
- 固定形式の一覧化: Luna
- 実装: Terra Worker
- 独立検証: Luna Verifier
- 上限超過: ウェーブ実行
- 最終判断と統合: 親

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
- 担当範囲が重なる可能性がある
- lockfile、設定、スキーマ、マイグレーション、生成コードを変更
- ある変更が別AgentのAPIや型へ影響
- 編集所有権を事前に完全分離できない

各Terra Workerは、指定worktree、ブランチ、基準コミットを確認し、担当変更だけをコミットします。Agent同士はmerge/rebaseせず、親がレビュー後に統合します。

## スレッド完了後の親レビュー

`complete`は自動承認を意味しません。

親は各スレッドについて次を確認します。

1. 期待したCustom Agent名とモデルが使われたか
2. 元の依頼、担当範囲、除外範囲、完了条件
3. 重要な主張のファイル、シンボル、コマンド、ログ
4. 実装のbase commit、worktree、ブランチ、最終コミット、差分、dirty状態
5. テスト結果と互換性
6. 他スレッドとの重複、矛盾、競合

判断は次の3種類です。

| 判断 | 扱い |
|---|---|
| `accepted` | 統合・最終回答に利用可能 |
| `revision-required` | 同じAgent/worktreeへ限定修正を依頼して再レビュー |
| `rejected` | 統合しない |

親自身の承認判断は別Agentへ委譲しません。統合後に再テストし、最終回答はレビューと統合検証が終わってから生成します。

## CLIプロファイル例

`profiles/sol-parent.config.toml`と`profiles/terra-parent.config.toml`は、Terra→Lunaを許可するため`max_depth = 2`に設定されています。

```bash
codex --profile sol-parent
```

## 更新

```bash
codex plugin marketplace upgrade tarou-imokenpi-plugins
git pull
bash ./scripts/install-agents.sh
```

更新後はCodex Appを再起動し、検証スクリプトを実行してください。

## トラブルシューティング

### 子スレッドがSolになる

原因候補:

- Custom Agentsをインストールしていない
- インストール後にCodex Appを再起動していない
- Skillが汎用Agentを起動した古いバージョン
- Agent名を正確に指定していない

対処:

```bash
git pull
bash ./scripts/install-agents.sh
bash ./scripts/verify-install.sh
```

その後、Codex Appを完全終了して再起動します。

### TerraがLunaを起動できない

`~/.codex/config.toml`で次を確認します。

```toml
[agents]
max_depth = 2
```

## License

MIT License
