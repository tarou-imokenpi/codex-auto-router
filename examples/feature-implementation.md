# Feature implementation with named agents and worktrees

通常の単一Issueでは、ユーザーは実装内容だけを入力します。

```text
@Auto Router このIssueを既存設計と公開APIに合わせて実装し、関連テスト、lint、型チェックまで実行してください。
```

複数領域を同時に変更する大規模実装でも、ユーザーがAgent名、ブランチ名、worktreeを指定する必要はありません。

```text
@Auto Router スレッドを使って、認証、教材生成、通知の3機能を実装し、それぞれのテストを追加してください。最後に統合状態をレビューして全体テストを実行してください。
```

Auto Routerは必要に応じて次を行います。

- 調査を正確な`terra_explorer`へ割り当てる
- 実装を正確な`terra_worker`へ割り当てる
- 独立検証を正確な`luna_verifier`へ割り当てる
- 汎用Agentや親Solを継承したスレッドへフォールバックしない
- 共通のbase commitを記録する
- 競合し得る各Terra Workerへ専用ブランチと`git worktree`を割り当てる
- 同じworktreeを複数の書き込みAgentで共有しない
- Terra内の局所検索・検証だけ、名前付きLuna子Agentを許可する
- 各Agentの実際の名前・モデル・変更を親がレビューする
- `accepted`になったコミットだけを親が統合する
- 競合解消と統合後テストを親が行う
- 不要になったworktreeと一時ブランチを安全に削除する
