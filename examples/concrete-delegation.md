# Concrete parent delegation examples

ユーザーはAgent割り当てを書きません。

```text
@Auto Router developブランチを監査し、認可の実害があるIssue候補だけを抽出してください。変更はしないでください。
```

親は必要な情報を確認した後、次のような具体的なbriefを生成します。

## Scanner brief

```text
CONTRACT_VERSION=1
WORKSTREAM_ID=auth-write-route-inventory
AGENT_NAME=spark_scanner
EXPECTED_MODEL=gpt-5.3-codex-spark
ROLE=scan

OBJECTIVE:
組織スコープの書き込みrouteを全件分類し、認可dependencyの有無を証拠付きで一覧化する。

SOURCE_OF_TRUTH:
- User requirement: 認可の実害があるIssue候補だけを抽出
- Base ref/commit: develop at <SHA>
- Repository instructions: <applicable AGENTS.md>

KNOWN_STATE:
- FastAPI routeはapps/backend/metis_backend/api以下にある
- 書き込み対象はPOST, PUT, PATCH, DELETE

DEPENDENCIES:
- Requires: none
- Enables: auth-bypass-review
- Parent wait rule: scanner完了・親accepted後にreviewerを開始

OWNED_SCOPE:
- Paths: apps/backend/metis_backend/api/**
- Selection rule: POST, PUT, PATCH, DELETE route
- Discovery boundary: route定義、handler、直接指定されたdependenciesまで

OUT_OF_SCOPE:
- admin専用route
- 認可設計の判断
- ソース変更

PERMISSIONS:
read-only

MANDATORY_STEPS:
1. 対象routeを列挙する。
2. handlerと認可dependencyを追跡する。
3. 重複aliasを統合し、指定schemaで返す。

DELIVERABLES:
- Columns: method, route, handler, auth dependency, classification, evidence
- Sort: route, method
- Completeness: 全件

ACCEPTANCE_CRITERIA:
- [ ] 対象の全write routeが分類されている
- [ ] 各行にroute定義とhandlerの証拠がある
- [ ] 認可dependencyの判定根拠がある
- [ ] alias重複が統合されている

VALIDATION:
- Commands: rgと対象ファイルの読み取りのみ
- Expected result: 対象route数と出力行数の対応が説明される

REQUIRED_EVIDENCE:
- route定義のpath:line
- handler symbol
- dependency指定のpath:line

STOP_CONDITIONS:
- Spark利用不可、非テキスト入力、scopeが大きすぎる、モデル不一致
- On stop: unsupportedまたはblocked。fallbackは親が作成する。

FALLBACK_POLICY:
Spark失敗時は同一objective/scope/schema/criteriaでluna_scanner briefを新規作成する。
```

## Reviewer brief

Scanner結果が親レビューでacceptedになった後に作成します。

```text
CONTRACT_VERSION=1
WORKSTREAM_ID=auth-bypass-review
AGENT_NAME=terra_reviewer
EXPECTED_MODEL=gpt-5.6-terra
ROLE=review

OBJECTIVE:
認可dependencyがない候補について、実際に別組織のデータへアクセスできるコード経路が存在するか判定し、実害のある問題だけを重要度順に報告する。

SOURCE_OF_TRUTH:
- Base ref/commit: develop at <SHA>
- Prior accepted result: auth-write-route-inventory
- Intended behavior: 組織スコープのデータは所属・権限確認なしに変更できない

DEPENDENCIES:
- Requires: accepted auth-write-route-inventory
- Enables: parent issue synthesis
- Parent wait rule: このreview完了までIssue候補を確定しない

OWNED_SCOPE:
- Candidate routes: <accepted candidate list>
- Discovery boundary: handlerからservice/repositoryおよび直接のauthorization pathまで

OUT_OF_SCOPE:
- 候補外routeの網羅監査
- 修正実装
- 認可ポリシー変更

PERMISSIONS:
read-only

REVIEW TARGET:
<candidate paths and symbols>

INTENDED BEHAVIOR:
別組織の利用者が対象resourceを読み書きできないこと。

PRIORITY LENSES:
authorization, tenant isolation, IDOR, missing regression tests

SEVERITY RUBRIC:
- critical: 広範な機密データまたは管理権限への無認証アクセス
- high: 別組織データの変更・削除が再現可能
- medium: 限定条件で別組織データの閲覧が可能

MATERIALITY:
具体的な攻撃経路または欠落テストを示せない指摘は除外する。

ACCEPTANCE_CRITERIA:
- [ ] 全候補について実行経路または反証がある
- [ ] 各findingに再現可能なcode pathまたはcounterexampleがある
- [ ] severityがrubricに対応している
- [ ] 重複findingが統合されている
```

## Worker brief

親が修正方針を承認した後にのみ作成します。

```text
CONTRACT_VERSION=1
WORKSTREAM_ID=fix-guide-delete-auth
AGENT_NAME=terra_worker
EXPECTED_MODEL=gpt-5.6-terra
ROLE=implement

OBJECTIVE:
学習ガイド削除時にorganization ownershipを必須化し、公開APIレスポンスを維持したまま回帰テストを通す。

SOURCE_OF_TRUTH:
- Accepted finding: <finding id>
- Approved behavior: 所有組織だけが削除可能
- Base commit: <SHA>

OWNED_SCOPE:
- apps/backend/metis_backend/guides/delete.py
- apps/backend/tests/guides/test_delete.py

OUT_OF_SCOPE:
- OpenAPI変更
- DB migration
- 共通認可frameworkの置換

PERMISSIONS:
workspace-write within owned scope

WORKTREE:
- Required: true
- Base commit: <SHA>
- Path: ../.codex-worktrees/fix-guide-delete-auth
- Branch: codex/auto-router/fix-guide-delete-auth

MANDATORY_STEPS:
1. 現在の削除経路とテスト規約を確認する。
2. 最小のownership checkを実装する。
3. 成功・別組織拒否・存在しないresourceのテストを追加する。
4. 指定テストを実行して1 commitにまとめる。

ACCEPTANCE_CRITERIA:
- [ ] 別組織の削除が拒否される
- [ ] 正当な所有者の削除が成功する
- [ ] APIレスポンスschemaが変わらない
- [ ] 指定テストがexit 0
- [ ] owned scope外の変更がない

VALIDATION:
- uv run pytest apps/backend/tests/guides/test_delete.py -q
- uv run mypy apps/backend/metis_backend/guides/delete.py
```

このように、親はトピックだけではなく、開始条件、担当範囲、除外範囲、成果物、受入条件、証拠、停止条件まで具体化してからAgentを起動します。
