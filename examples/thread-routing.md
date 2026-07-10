# Large task with named custom-agent threads

ユーザーは次だけ入力します。

```text
@Auto Router スレッドを使って、このリポジトリ全体を領域別に監査してください。根拠のあるIssue候補だけを重要度順に統合し、変更はしないでください。
```

Auto Routerは次を行います。

- 親のSol/Terraが非重複の作業領域を定義
- 横断判断は`terra_explorer`や`terra_reviewer`など、正確なCustom Agent名を指定して起動
- 明確でテキスト中心の一覧化は` spark_scanner`を第一候補にする
- Sparkが未提供、非対応、非テキスト、容量不足、起動失敗、モデル不一致の場合だけ`luna_scanner`へ再割り当てる
- 検証は`luna_verifier`へ割り当てる
- TerraがローカルScanner/Verifierを必要とする場合のみ、`max_depth = 2`で名前付き子Agentを起動
- 汎用Agentや親Solを継承したスレッドへフォールバックしない
- 同時実行上限に達する場合はウェーブ実行
- 親が実際のAgent名・モデル・Sparkフォールバック理由・根拠をレビューし、`accepted`のみ統合
