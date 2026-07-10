# Codex Auto Router

GPT-5.6のSol・Terra・LunaとGPT-5.3-Codex-Sparkを、Codexの**名前付きCustom Agent**として自動で使い分けるルータープラグインです。

Codex Appでは、サブエージェントがそれぞれ「agent thread」として表示されます。Auto Routerは、親のSolまたはTerraからモデル固定済みCustom Agentを起動します。

```text
@Auto Router developブランチを横断的に分析して、重要度別にIssue候補を抽出してください。変更はしないでください。
```

ユーザーが毎回、Agent名、モデル、フォールバック、並列数、worktree、レビュー手順を書く必要はありません。

## スキャン処理はSpark優先、Lunaフォールバック

検索、抽出、一覧化、分類、コンパクトなリポジトリマップなど、明確でテキスト中心のスキャン処理は、まず`gpt-5.3-codex-spark`固定の` spark_scanner`へ割り当てます。

次の場合だけ`gpt-5.6-luna`固定の`luna_scanner`へ切り替えます。

- Sparkが現在のアカウント、プラン、クライアント、セッションで利用できない
- `spark_scanner`が現在のセッションへ読み込まれていない
- 画像などテキスト以外の入力が必要
- 必要なコンテキストがSparkで安全に扱える範囲を超える
- Sparkの起動が失敗する
- unsupported model、access、preview capacity、rate limitなどのエラーになる
- Sparkを期待したのに別モデルが表示される

Sparkは現在、ChatGPT Pro向けのテキスト専用Research Previewです。利用可否は変動し得るため、Lunaフォールバックを常に残します。

フォールバック時は理由と実際に使われたAgent・モデルを記録し、Sparkを使ったようには報告しません。Sparkの部分結果とLunaの結果も黙って混ぜず、親が破棄・置換・独立証拠のどれとして扱うかレビューします。

## 重要: プラグイン単体ではモデル固定されません

CodexのプラグインはSkillを配布できますが、Custom Agentを自動登録する仕組みではありません。

Custom Agentが読み込まれていない状態で汎用スレッドを作ると、子は親のモデル設定を継承するかCodexの自動選択になります。親がSolなら、子スレッドもSolになることがあります。

そのため、**Marketplaceからプラグインを入れるだけでなく、Custom Agentsのインストールが必須**です。Auto Routerは必要な名前付きAgentが見つからない場合、汎用Agentへフォールバックしません。ただしSparkだけが利用できない場合は、名前付き`luna_scanner`へフォールバックします。

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

検証スクリプトはCustom Agentファイルと固定モデルを確認します。Sparkが実際に現在のアカウントで利用可能かは実行時に判定され、未対応ならLunaへフォールバックします。

## Custom Agent一覧

| Custom Agent | 固定モデル | 推論 | 用途 |
|---|---|---|---|
| `terra_explorer` | `gpt-5.6-terra` | Medium | 横断調査、実行経路、影響範囲、原因分析 |
| `terra_reviewer` | `gpt-5.6-terra` | High | 正しさ、セキュリティ、回帰、互換性レビュー |
| `terra_worker` | `gpt-5.6-terra` | Medium | 担当範囲を限定した実装 |
| `spark_scanner` | `gpt-5.3-codex-spark` | Low | 優先スキャナー。高速な検索、抽出、一覧化、分類 |
| `luna_scanner` | `gpt-5.6-luna` | Low | Spark非対応時のスキャナーフォールバック |
| `luna_verifier` | `gpt-5.6-luna` | Medium | テスト、lint、型チェック、再現確認 |

すべてのTOMLで`model`を明示しているため、名前付きAgentが正しく起動すれば親Solを継承しません。

## 親・Terra・Spark・Lunaの階層

```text
親 Sol / Terra（depth 0）
├─ terra_explorer / terra_reviewer / terra_worker（depth 1）
│  ├─ spark_scanner（depth 2、スキャンの第一候補）
│  ├─ luna_scanner（depth 2、Sparkフォールバック）
│  └─ luna_verifier（depth 2、検証）
├─ spark_scanner（depth 1、スキャンの第一候補）
├─ luna_scanner（depth 1、Sparkフォールバック）
└─ luna_verifier（depth 1、検証）
```

ルール:

- 親はSolまたはTerra
- 親は正確な名前付きAgentを直接起動可能
- スキャンは` spark_scanner`を優先し、非対応時のみ`luna_scanner`
- Terraは契約で許可された場合のみ、名前付きScannerまたはVerifierを起動可能
- TerraはSol、Terra、汎用Agentを子として起動しない
- SparkとLunaは末端Agentであり、子Agentを起動しない
- Terraから子Agentを起動するには`agents.max_depth >= 2`が必要
- 同時スレッド上限を超える場合は複数ウェーブで実行

## モデル不一致時の扱い

親は起動前後にCustom Agent名と表示モデルを確認します。

次の場合は、そのスレッドを期待モデルの成果として採用しません。

- `default`、`worker`、`explorer`などの汎用Agentが起動された
- Terraを期待したのにSolとして表示された
- Sparkを期待したのに別モデルとして表示された
- Lunaを期待したのに別モデルとして表示された
- 必要なCustom Agentが現在のセッションに読み込まれていない

Sparkだけが失敗した場合は、理由を記録して同じ作業範囲を`luna_scanner`へ再割り当てします。TerraやVerifierが見つからない場合は、親だけで小さな作業を続けるかセットアップ不足として停止します。

## 大規模タスク

```text
@Auto Router スレッドを使って、このリポジトリ全体を領域別に監査し、根拠のあるIssue候補だけを統合してください。
```

Auto Routerは領域ごとに正確な名前付きAgentを割り当てます。

- 判断や横断分析: Terra
- テキスト中心の一覧化: Sparkを優先、非対応ならLuna Scanner
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

各Terra Workerは指定worktree、ブランチ、基準コミットを確認し、担当変更だけをコミットします。Agent同士はmerge/rebaseせず、親がレビュー後に統合します。ScannerとVerifierは同じ割当worktree内で読み取り・検証だけを行います。

## スレッド完了後の親レビュー

`complete`は自動承認を意味しません。親は各スレッドについて次を確認します。

1. 期待したCustom Agent名とモデルが使われたか
2. Sparkを使わなかった場合、そのフォールバック理由が妥当か
3. 元の依頼、担当範囲、除外範囲、完了条件
4. 重要な主張のファイル、シンボル、コマンド、ログ
5. 実装のbase commit、worktree、ブランチ、最終コミット、差分、dirty状態
6. テスト結果と互換性
7. 他スレッドとの重複、矛盾、競合

判断は次の3種類です。

| 判断 | 扱い |
|---|---|
| `accepted` | 統合・最終回答に利用可能 |
| `revision-required` | 同じAgent/worktreeへ限定修正を依頼して再レビュー |
| `rejected` | 統合しない |

親自身の承認判断は別Agentへ委譲しません。統合後に再テストし、最終回答はレビューと統合検証が終わってから生成します。

## 更新

```bash
codex plugin marketplace upgrade tarou-imokenpi-plugins
git pull
bash ./scripts/install-agents.sh
bash ./scripts/verify-install.sh
```

更新後はCodex Appを再起動してください。

## トラブルシューティング

### Sparkが起動できない

SparkはChatGPT Pro向けResearch Previewで、利用状況や容量によりアクセスできない場合があります。これはAuto Router全体の失敗ではありません。`luna_scanner`へフォールバックし、実際のモデルを親が確認します。

### 子スレッドがSolになる

原因候補:

- Custom Agentsをインストールしていない
- インストール後にCodex Appを再起動していない
- Skillが汎用Agentを起動した古いバージョン
- Agent名を正確に指定していない

```bash
git pull
bash ./scripts/install-agents.sh
bash ./scripts/verify-install.sh
```

その後、Codex Appを完全終了して再起動します。

### Terraが子Agentを起動できない

`~/.codex/config.toml`で次を確認します。

```toml
[agents]
max_depth = 2
```

## License

MIT License
