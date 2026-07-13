# yazi API spike (2026-07-13)

Task 1 の spike。実装前の API 前提を確定させる。

## 環境

- yazi 26.5.6 (aa52643 2026-05-05) — v25.5.31 minimum を大幅に超えるので OK

## 決定的な findings

### 1. `Manager.quit` フックは存在しない (計画の前提が誤り)

`~/.config/yazi/init.lua` から `Manager.quit = function ... end` の形で quit をフックする API は存在しない。

- yazi 公式リポの source 検索で `Manager.quit` / `Manager:quit` のヒット 0 件
- 公式 tips の "Confirm before quitting" 例も、plugin + keymap の形で `q` を bind してから内部で `ya.emit("quit", {})` を呼ぶ手法
- autosession / pref-by-location とも同じ plugin+keymap パターン

**帰結**: 計画の「init.lua に直書き」方針は成立しない。プラグインディレクトリを作らないと `q` をフックできない。

### 2. `ya.json_encode` / `ya.json_decode` は存在する (ドキュメント漏れ)

公式 docs の Utilities ページには載っていないが、pref-by-location.yazi が本番で使用中:

```lua
-- ~/.config/yazi/plugins/pref-by-location.yazi/main.lua
local prefs = hex_decode_table(ya.json_decode(prefs_encoded))
-- ...
local _, err_write = fs.write(save_path, ya.json_encode(hex_encode_table(prefs_tmp)))
```

**帰結**: 手書き JSON エンコーダは不要。`ya.json_encode` / `ya.json_decode` を直接使う。

### 3. ファイル I/O のコンテキスト制約

- `io.open` / `io.read` / `io.write` — 標準 Lua、sync コンテキストで動作 (pref-by-location の実績)
- `fs.write` / `fs.read` / `fs.file` — yazi 提供、async コンテキスト限定 (docs の "async-context only" 記述と実装で確認)

**帰結**: `ya.sync(...)` 内では `io.*` を使う。プラグインの `entry` / `setup` 直下 (async) では `fs.*` も使える。

### 4. `reveal` コマンドの引数仕様

pref-by-location の実装から:

```lua
ya.emit("reveal", {
  url_string,               -- 位置引数1: 絶対 URL
  no_dummy = true,          -- キー引数: dummy file を挟まない
  raw = true,               -- キー引数: URL をそのまま解釈
  tab = cx.active.id,       -- 任意: 対象タブ
})
```

**帰結**: `reveal <url>` で cd + カーソル位置決めが 1 コマンドで走る。フォルダ非同期ロード待ちは yazi 側が担う。

### 5. `toggle_all` による bulk selection

yazi 公式の fzf preset プラグイン (`yazi-plugin/preset/plugins/fzf.lua`) から:

```lua
local files = {}
for _, url in ipairs(urls) do
  files[#files + 1] = fs.file(url)
end
if #files > 0 then
  files.state = #selected > 0 and "off" or "on"
  ya.emit("toggle_all", files)
end
```

- 引数: `fs.file(url)` オブジェクトの配列
- `state = "on"|"off"` フィールドで一括 on/off
- **`fs.file` は async 前提** — 選択復元は async context で組む

**帰結**: 選択復元は per-URL の `reveal + toggle` ループではなく `toggle_all` 1 発でよい。

### 6. `tab_create` / `tab_switch`

autosession から:

```lua
ya.emit("tab_create", { tab.cwd })     -- URL を第1引数に取れる
ya.emit("tab_switch", { active_idx - 1 })  -- 0-indexed
```

`cx.tabs.idx` は 1-indexed なので、tab_switch に渡すときは `- 1`。

### 7. `sort` / `linemode` / `hidden` の引数

autosession の実装で確認済み:

```lua
ya.emit("sort", {
  by = "natural",
  reverse = false,
  dir_first = true,
  sensitive = false,
  translit = false,
})
ya.emit("linemode", { "size" })
ya.emit("hidden", { "show" })  -- or "hide"
```

## 実装方針への影響

計画 (`docs/superpowers/plans/2026-07-13-yazi-persist-by-launch.md`) の以下を修正する:

### 前提の変更

- **削除**: 「init.lua 直書き / プラグインディレクトリ不要」
- **追加**: `dot_config/yazi/plugins/persist-by-launch.yazi/main.lua` を新規作成する
- **変更**: `init.lua` は `require("persist-by-launch"):setup()` のみ
- **変更**: `keymap.toml` は autosession → persist-by-launch へ `q` の run 先を差し替える (削除ではなく置換)

### タスク再編

- **Task 2**: 「skeleton を init.lua に追加」→ **「plugins/persist-by-launch.yazi/main.lua を作成し init.lua で require」**
- **Task 3**: Manager.quit フック → **entry("save-and-quit") 実装 + keymap q の差し替え**
- **Task 4**: 起動時 restore は `ps.sub_remote` パターン (autosession と同じ)
- **Task 5-7**: 場所を init.lua → 新プラグインの main.lua に置換
- **Task 8**: cleanup 内容は同じ (autosession/pref-by-location 撤去) — ただし keymap の `q` は persist-by-launch を指したまま残す

### JSON ヘルパ

`ya.json_encode` / `ya.json_decode` が使えるので、手書きエンコーダは不要。

### 選択復元

per-URL `reveal + toggle` ループを想定していたが、`toggle_all` で 1 発で済む。実装が単純化される。
