# Large task with named custom-agent threads

ユーザーは次だけ入力します。

```text
@Auto Router スレッドを使って、このリポジトリ全体を領域別に監査してください。根拠のあるIssue候補だけを重要度順に統合し、変更はしないでください。
```

Auto Routerは次を行います。

- 親のSol/Terraが非重複の作業領域を定義
- `terra_explorer`や`terra_reviewer`など、正確なCustom Agent名を指定して起動
- 明確で機械的な一覧化は`luna_scanner`へ割り当て
- Terraがローカル検証を必要とする場合のみ、`max_depth = 2`で名前付きLunaを起動
- 汎用Agentや親Solを継承したスレッドへフォールバックしない
- 同時実行上限に達する場合はウェーブ実行
- 親が実際のAgent名・モデル・根拠をレビューし、acceptedのみ統合
