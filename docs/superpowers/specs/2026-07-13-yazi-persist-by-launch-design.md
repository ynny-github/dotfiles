# yazi: launch cwd 単位のセッション永続化

- 日付: 2026-07-13
- ステータス: draft (レビュー待ち)
- 実装場所: `dot_config/yazi/init.lua` (直書き)

## 目的

yazi を起動した親シェルの `$PWD` (**launch cwd**) を単位に、前回終了時の作業状態を JSON ファイルに保存し、次回同じ場所から yazi を起動した時に自動復元する。

例: `~/proj-a` で yazi 起動 → `src/lib` まで潜って複数ファイルを選択 → `q` → 次回 `~/proj-a` から起動すると `src/lib` に選択状態のまま復帰する。

## 動機と非目標

### 既存プラグインとの比較

| プラグイン | キー単位 | 保存対象 | 課題 |
|---|---|---|---|
| `autosession.yazi` | グローバル (単一) | タブ+cwd+sort+linemode+hidden | プロジェクトを跨ぐと混ざる |
| `pref-by-location.yazi` | 訪問中の各ディレクトリ | sort+linemode+hidden のみ | 前回 cwd/カーソル/選択を復元できない |

launch cwd をキーにする自作方式は、両者のいずれでも達成できない「プロジェクトごとに前回の作業位置を丸ごと復元する」を実現する。

### 非目標

- **プラグインパッケージ化しない** — 個人設定のため `init.lua` 直書き。他マシンで `ya pkg add` 配布する予定なし。
- **タスク (バックグラウンドジョブ) の復元は扱わない** — yazi API に復元コマンドなし。
- **backstack (ナビ履歴) の復元は扱わない** — API 欠損。
- **marker (`m` で付けるマーク) の復元は扱わない** — 読み出せるが emit で set する手段なし。
- **preview scroll / filter / find / yank の復元は扱わない** — 一時的作業状態のため、セッション終了で消えるのが自然。

## 保存する state

launch cwd をキーに、以下を JSON に保存する:

```json
{
  "/Users/yn/proj-a": {
    "active": 2,
    "tabs": [
      {
        "cwd": "/Users/yn/proj-a/src",
        "cursor": "main.rs",
        "selected": ["/Users/yn/proj-a/src/lib.rs"],
        "sort": {
          "by": "natural",
          "reverse": false,
          "dir_first": true,
          "sensitive": false,
          "translit": false
        },
        "linemode": "size",
        "show_hidden": false
      }
    ]
  }
}
```

### フィールド定義

- `active` (number) — アクティブタブの 1-indexed インデックス
- `tabs` (array) — タブごとの状態
  - `cwd` (string) — タブの作業ディレクトリ絶対パス
  - `cursor` (string | null) — ホバー中ファイルの basename。ホバーなし時は null
  - `selected` (string[]) — 選択中ファイルの絶対パス配列
  - `sort` (object) — yazi の sort 設定と同一構造
  - `linemode` (string) — `none | size | btime | mtime | permissions | owner` またはカスタム
  - `show_hidden` (boolean)

## 保存先

`~/.local/state/yazi/persist-by-launch.json` (XDG_STATE_HOME 準拠)

- 単一ファイルに全 launch cwd のエントリを持つ辞書形式
- 起動時に読み込み → 対応エントリだけ復元
- 終了時に読み込み → 該当エントリを更新 → 書き戻し (他エントリは保持)

## 動作フロー

### 起動時 (`init.lua` 実行時)

1. yazi の同期コンテキスト (`ya.sync`) で `cx.tabs[1].current.cwd` を取得し、`state.launch_cwd` にキャッシュする
2. JSON ファイルを `io.open` で読み込む。存在しない or パース失敗なら何もせず終了
3. `state.launch_cwd` に対応するエントリがなければ何もせず終了
4. あれば **復元シーケンス** を発火

### 復元シーケンス

autosession と同様に `ps.sub_remote` パターンを使い、初回のみ発火する `state.restored` フラグでガードする。

1. **タブ数の調整**
   - 目標タブ数 = `entry.tabs` の長さ
   - 現在タブ数 (通常 1) が不足なら `tab_create <cwd>` を差分回数、余分なら末尾から `tab_close` (通常発生しないが防御的に)
2. **各タブについて順に**:
   - `tab_switch <idx>` で対象タブへ切り替え
   - `cd <tab.cwd>` で作業ディレクトリ移動
   - `sort` を `tab.sort` の各フィールドで emit
   - `linemode <tab.linemode>`
   - `hidden <show|hide>`
   - `cursor` が非 null なら `reveal <tab.cwd>/<cursor>` を emit (絶対位置決め + フォルダ非同期ロード完了待ちを yazi 側に任せる)
   - `selected` の各 URL について、`reveal <url>` → `toggle` を反復 (順序と非同期性は技術リスク項目で検証)
3. **最後に active タブへ切り替え**: `tab_switch <entry.active - 1>`
4. `state.restored = true`

### 終了時 (`q` キー)

`init.lua` で `Manager.quit` を上書きし、quit 実行前に state 収集と保存を行う:

```lua
local _quit = Manager.quit
Manager.quit = function(self, job)
  save_current_state()
  return _quit(self, job)
end
```

`save_current_state` の処理:

1. `cx.tabs` を走査して各タブの `{cwd, cursor, selected, sort, linemode, show_hidden}` を収集
2. active タブ index を `cx.tabs.idx` から取得
3. JSON ファイルを読み込み (なければ空辞書)
4. `state.launch_cwd` のエントリを新規または上書き
5. JSON ファイルに書き戻し (親ディレクトリがなければ `os.execute("mkdir -p ...")` で作成)

`Manager.quit` フックはデフォルトの `q` キーで発火する。したがって `keymap.toml` の autosession 用 `q` 上書きは削除する。

## エラー処理

- **cwd が存在しない**: 該当タブをスキップ (最低 1 タブは launch cwd で開く)
- **選択/カーソル対象ファイルが存在しない**: 該当のみスキップ、他は続行
- **JSON パースエラー**: エントリなし扱いで通常起動 (破損ファイルは上書き時に修復される)
- **ファイル書き込みエラー**: ログ (`ya.dbg`) を出して quit は続行 (阻害しない)

## 変更ファイル

### chezmoi 管理下

- **編集**: `dot_config/yazi/init.lua` — persist-by-launch の全ロジック
- **編集**: `dot_config/yazi/keymap.toml` — autosession 用 `q` 上書きを削除
- (`dot_config/yazi/yazi.toml` は変更なし)

### chezmoi 管理外 (手動)

- `~/.config/yazi/package.toml` から `barbanevosa/autosession` と `boydaihungst/pref-by-location` を削除
- `ya pkg upgrade` (or `rm -rf`) で `~/.config/yazi/plugins/autosession.yazi/` と `~/.config/yazi/plugins/pref-by-location.yazi/` を撤去
- `piper.yazi` は残す (markdown プレビューで使用中)

## 技術リスクと検証項目

実装時に yazi の実 API 挙動を確認する必要がある項目:

### 1. cursor / selection 復元と非同期ロード

`cd` 直後、`cx.active.current.files` は非同期ロード。`reveal <url>` を使うことで yazi 側が「そのファイルが現れたらカーソルを合わせる」処理を担うため、明示的な待機は不要になる想定。ただし:

- `reveal` を連続 emit した場合、最後の `reveal` に上書きされる可能性 → 選択復元では **各 `reveal` → `toggle` を 1 セットとしてキュー処理**する必要があるかもしれない
- 上記が破綻するなら fallback として `ya.sleep(0.05)` + `arrow <index>` に切り替え

### 2. selection の bulk API 有無

`reveal + toggle` の反復が唯一の手段か、URL リストを引数に取る一括 API があるかを確認。あれば大幅に単純化できる。

### 3. `tab_create` の引数仕様

`tab_create <cwd>` で URL 引数を取れるか未確認。取れなければ `tab_create` → 新タブに `tab_switch` → `cd <cwd>` の順で書く。

### 4. `Manager.quit` フックの網羅性

- デフォルトの `q` キー: フックされる想定
- `close` コマンド (タブが 1 つの時): 別ハンドラの可能性 → 検証
- SIGTERM / ターミナル閉じ: yazi 側で quit を経由するか不明 → 検証 (経由しなければ諦める。「異常終了時は保存されない」旨をドキュメント)

### 5. yazi の JSON ヘルパ

`ya.json_encode` / `ya.json_decode` が存在するか。無ければ小さな手書き JSON エンコーダを同梱 (state 構造は決まっているので 30 行程度)。

## テスト観点 (実装時)

- 単一タブでの cd 復元
- 複数タブでの cwd + active タブ復元
- カーソル位置の復元
- 選択 (multi-select) の復元
- sort / linemode / hidden の復元
- 前回 cwd が削除されている場合の fallback
- 選択ファイルが削除されている場合の skip
- JSON ファイルが破損している場合の fallback
- launch cwd がまだ登録されていない (初回起動) 場合の何もしない挙動
- 2 つの異なる launch cwd で交互に開いた時、それぞれの state が独立していること

## 実装後の運用

- 保存ファイルが肥大化した場合の掃除: cwd が存在しないエントリを起動時に prune するオプションを将来検討 (今は YAGNI)
- init.lua が 200 行を超えたら `plugins/persist-by-launch.yazi/` に切り出す

## 参考

- autosession: `~/.config/yazi/plugins/autosession.yazi/main.lua` — save-and-quit と ps.sub_remote パターン
- pref-by-location: `~/.config/yazi/plugins/pref-by-location.yazi/main.lua` — `io.open` によるディスク永続化パターン
- yazi 公式: https://yazi-rs.github.io/docs/plugins/overview
