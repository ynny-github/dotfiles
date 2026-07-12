# yazi persist-by-launch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** yazi の launch cwd 単位で「前回のタブ構成/cwd/カーソル位置/選択/表示設定」を JSON に保存し、次回起動時に自動復元する機能を、`~/.config/yazi/init.lua` に直書きで実装する。

**Architecture:** 単一 `init.lua` 内で `ya.sync(function(state) ... end)` の state テーブルに launch cwd と復元済みフラグを持つ。`Manager.quit` を上書きして終了直前に state を JSON にディスク保存。起動時に JSON を読み、launch cwd に対応するエントリがあれば `cd` / `tab_create` / `sort` / `linemode` / `hidden` / `reveal` / `toggle` を emit して復元。

**Tech Stack:** yazi >= v25.5.31 の Lua プラグイン API、`io.open` によるファイル I/O、`os.getenv("HOME")` によるパス解決、手書き JSON エンコーダ/デコーダ (yazi の `ya.json_encode`/`ya.json_decode` が使えなければ)。

## Global Constraints

- 対象は個人の `~/.config/yazi/init.lua` 一箇所のみ。プラグインディレクトリを新規作成しない。
- chezmoi 管理下の変更ファイルは `dot_config/yazi/init.lua` と `dot_config/yazi/keymap.toml` のみ。他ファイルは触らない。
- yazi の autosession.yazi と pref-by-location.yazi は最後に撤去する。それまでは併存させて壊さない。
- JSON 保存先は `~/.local/state/yazi/persist-by-launch.json` (XDG_STATE_HOME 準拠)。親ディレクトリが無ければ作成する。
- 復元は起動 1 回のみ (autosession と同様の `state.restored` フラグでガード)。
- 現在の `q` = autosession 保存を維持する形で開発する (最終タスクで置き換え)。開発途中で quit の挙動を壊さない。
- 例外や欠損 (JSON 破損、cwd 消失、選択ファイル消失) は「静かに fallback して通常起動」を貫く。エラーで yazi を止めない。

---

## File Structure

**変更するファイル:**

- **`dot_config/yazi/init.lua`** (編集) — persist-by-launch のロジック全体を追加。既存の `require("autosession"):setup()` は最終タスクまで残す。
- **`dot_config/yazi/keymap.toml`** (編集) — 最終タスクで autosession の `q` バインディングを削除。それまで触らない。

**chezmoi 管理外で手動操作するファイル (最終タスク):**

- `~/.config/yazi/package.toml` — `barbanevosa/autosession` と `boydaihungst/pref-by-location` の `[[plugin.deps]]` エントリを削除
- `~/.config/yazi/plugins/autosession.yazi/` — ディレクトリごと削除
- `~/.config/yazi/plugins/pref-by-location.yazi/` — ディレクトリごと削除
- `~/.local/state/yazi/persist-by-launch.json` — 新規作成される (実装が作る)

**テスト戦略:** yazi 用の自動テスト環境は存在しないので、各タスク末尾で **手動検証手順** を実行する。TDD の「先にテスト」の代わりに **先に検証手順を書き** → 実装 → 手動検証 → コミット、というフローを取る。

---

## Task 1: yazi API の spike 検証

**目的:** 設計 spec の技術リスク項目 (§技術リスクと検証項目) を実装前に潰す。実装しない、調べるだけ。

**Files:**
- Create: `docs/superpowers/notes/2026-07-13-yazi-api-spike.md` — 検証結果を書き残す

**Interfaces:**
- Consumes: なし
- Produces: 後続タスクは以下の情報を前提にできる:
  - `ya.json_encode` / `ya.json_decode` の有無
  - `Manager.quit` フックが `q` キーで発火するか
  - `reveal <url>` が cd + カーソル位置決めを一度に行うか
  - `tab_create` が cwd 引数を取るか
  - selection の bulk API 有無

- [ ] **Step 1: yazi バージョン確認**

Run: `yazi --version`
Expected: `Yazi 25.x.x` — v25.5.31 以上であること (pref-by-location の最低要件)

- [ ] **Step 2: yazi ドキュメントで API 確認**

以下の URL を Read (WebFetch):
- https://yazi-rs.github.io/docs/plugins/overview
- https://yazi-rs.github.io/docs/plugins/utils
- https://yazi-rs.github.io/docs/plugins/types
- https://yazi-rs.github.io/docs/configuration/keymap (reveal, toggle, sort, linemode, hidden, cd, tab_create, tab_switch, tab_close, quit)

以下を確認して `docs/superpowers/notes/2026-07-13-yazi-api-spike.md` にメモ:
- `ya.json_encode(value)` / `ya.json_decode(str)` の有無と使用法
- `ya.dbg` / `ya.err` の使い方 (エラーログ)
- `reveal` コマンドの引数仕様 (URL 絶対パス / --raw / --no-dummy)
- `tab_create` の引数仕様 (URL を取るか)
- `toggle` コマンドの引数 (URL を取れるか、hovered ファイルのみか)
- `Manager.quit` が override 可能なフックポイントか (Custom Commands セクション参照)

- [ ] **Step 3: 実験用 init.lua で quit フックを検証**

`~/.config/yazi/init.lua` の末尾に一時追加 (最後に消す):

```lua
if Manager and Manager.quit then
  local _quit = Manager.quit
  Manager.quit = function(self, job)
    ya.dbg("persist-spike: Manager.quit fired")
    return _quit(self, job)
  end
end
```

`YAZI_LOG=debug yazi` で起動し `q` で終了。`~/.local/state/yazi/yazi.log` (or 環境の該当ログ) に `persist-spike: Manager.quit fired` が出るか確認。

一時コードを削除して init.lua を元に戻す (変更をコミットしない)。

- [ ] **Step 4: 結果をノートにまとめる**

`docs/superpowers/notes/2026-07-13-yazi-api-spike.md` に以下を必ず記載:
- `ya.json_encode`/`ya.json_decode` の有無 → 無ければ手書きエンコーダが必要
- `Manager.quit` フックが動いた/動かなかった
- `reveal <url>` の受け入れる引数形式
- `tab_create` に URL を渡せるか
- `toggle` の引数仕様
- 追加で見つかった有用な API / 落とし穴

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/notes/2026-07-13-yazi-api-spike.md
git commit -m "docs: yazi API spike results for persist-by-launch"
```

---

## Task 2: 空の persist-by-launch ロジックを init.lua に追加 (無害な skeleton)

**目的:** state テーブル + launch cwd キャッシュ + no-op な save/restore 関数を追加。autosession は保持したまま、init.lua への追加が既存動作を壊さないことを確認する。

**Files:**
- Modify: `dot_config/yazi/init.lua`

**Interfaces:**
- Produces:
  - `persist` (module-local Lua table) — フィールド: `launch_cwd`, `restored`, `state_file`
  - `persist:save()` — 現在の state を JSON に書く (Task 3 で中身を入れる)
  - `persist:restore()` — JSON から復元 (Task 4 で中身を入れる)
  - `persist:setup()` — 起動時初期化

- [ ] **Step 1: 現状の init.lua を確認 (手順のみ)**

Run: `cat ~/.local/share/chezmoi/dot_config/yazi/init.lua`
Expected:
```lua
-- ~/.config/yazi/init.lua
require("autosession"):setup()
```

- [ ] **Step 2: init.lua に skeleton を追加**

`dot_config/yazi/init.lua` を以下に置き換え:

```lua
-- ~/.config/yazi/init.lua

require("autosession"):setup()

-- persist-by-launch: launch cwd 単位でセッションを保存/復元する
local persist = {
  launch_cwd = nil,
  restored = false,
  state_file = os.getenv("HOME") .. "/.local/state/yazi/persist-by-launch.json",
}

function persist:save()
  -- Task 3 で実装
end

function persist:restore()
  -- Task 4 で実装
end

function persist:setup()
  -- launch cwd をキャッシュ
  local sync_launch_cwd = ya.sync(function()
    return tostring(cx.tabs[1].current.cwd)
  end)
  self.launch_cwd = sync_launch_cwd()
  ya.dbg("persist-by-launch: launch_cwd=" .. tostring(self.launch_cwd))
end

persist:setup()
```

- [ ] **Step 3: chezmoi apply して yazi を起動、無害であることを確認**

Run: `chezmoi apply ~/.config/yazi/init.lua && YAZI_LOG=debug yazi`
Expected:
- yazi が普通に起動する
- 何もせず `q` で終了 (autosession が動く)
- `~/.local/state/yazi/yazi.log` に `persist-by-launch: launch_cwd=/Users/yn/...` の行がある

- [ ] **Step 4: Commit**

```bash
git add dot_config/yazi/init.lua
git commit -m "feat(yazi): add persist-by-launch skeleton to init.lua"
```

---

## Task 3: save 関数を実装して JSON に書き出す

**目的:** `Manager.quit` フックで現在の state (1タブ想定の cwd/sort/linemode/hidden) を JSON に書く。cursor と selection と多タブは後続タスク。

**Files:**
- Modify: `dot_config/yazi/init.lua`

**Interfaces:**
- Consumes: `persist.launch_cwd`, `persist.state_file` (Task 2)
- Produces:
  - `persist:save()` が動作する
  - `~/.local/state/yazi/persist-by-launch.json` に `{ "<launch_cwd>": { "active": 1, "tabs": [{...}] } }` 形式で書かれる
  - タブ内フィールド: `cwd`, `sort`, `linemode`, `show_hidden` (cursor/selected は空/null で埋める)

- [ ] **Step 1: 手動検証手順を書き出す (先に定義)**

- yazi を `~/.config/nvim` から起動
- 何もせず `q` で終了
- `cat ~/.local/state/yazi/persist-by-launch.json` を実行
- 期待: `{"/Users/yn/.config/nvim":{"active":1,"tabs":[{"cwd":"/Users/yn/.config/nvim","cursor":null,"selected":[],"sort":{...},"linemode":"...","show_hidden":false}]}}` に相当する JSON

- [ ] **Step 2: JSON ヘルパを追加**

Task 1 で `ya.json_encode` が存在するとわかっていれば、これをラップ:

```lua
local function json_encode(value)
  return ya.json_encode(value)
end

local function json_decode(str)
  local ok, result = pcall(ya.json_decode, str)
  if not ok then return nil end
  return result
end
```

`ya.json_encode` が無い場合は手書きエンコーダ (spec の付録参照。Task 1 のノートに合わせて実装):

```lua
-- Task 1 の spike 結果に応じてこのブロックを埋める
-- ya.json_encode が使えるなら上のラッパーをそのまま採用
```

- [ ] **Step 3: ファイル読み書きヘルパを追加**

```lua
local function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  return content
end

local function ensure_dir(path)
  local dir = path:match("(.*)/[^/]+$")
  if dir then os.execute("mkdir -p '" .. dir .. "'") end
end

local function write_file(path, content)
  ensure_dir(path)
  local file = io.open(path, "w")
  if not file then return false end
  file:write(content)
  file:close()
  return true
end
```

- [ ] **Step 4: 現在の state を収集する ya.sync を追加**

```lua
local collect_state = ya.sync(function()
  local tabs = cx.tabs
  local session = {
    active = tabs.idx,
    tabs = {},
  }
  for i, tab in ipairs(tabs) do
    session.tabs[i] = {
      cwd = tostring(tab.current.cwd),
      cursor = nil,
      selected = {},
      sort = {
        by = tab.pref.sort_by,
        reverse = tab.pref.sort_reverse,
        dir_first = tab.pref.sort_dir_first,
        sensitive = tab.pref.sort_sensitive,
        translit = tab.pref.sort_translit,
      },
      linemode = tab.pref.linemode,
      show_hidden = tab.pref.show_hidden,
    }
  end
  return session
end)
```

- [ ] **Step 5: persist:save() を実装**

```lua
function persist:save()
  if not self.launch_cwd then return end
  local session = collect_state()
  local all = {}
  local existing = read_file(self.state_file)
  if existing then
    local decoded = json_decode(existing)
    if type(decoded) == "table" then all = decoded end
  end
  all[self.launch_cwd] = session
  local encoded = json_encode(all)
  if encoded then
    write_file(self.state_file, encoded)
  end
end
```

- [ ] **Step 6: Manager.quit をフック**

`persist:setup()` の末尾に追加:

```lua
if Manager and Manager.quit then
  local _quit = Manager.quit
  Manager.quit = function(self_mgr, job)
    persist:save()
    return _quit(self_mgr, job)
  end
end
```

- [ ] **Step 7: chezmoi apply して手動検証**

Run: `chezmoi apply ~/.config/yazi/init.lua && cd ~/.config/nvim && rm -f ~/.local/state/yazi/persist-by-launch.json && yazi`

yazi 内で `q` 終了後、以下を確認:

Run: `cat ~/.local/state/yazi/persist-by-launch.json | python3 -m json.tool`
Expected:
```json
{
  "/Users/yn/.config/nvim": {
    "active": 1,
    "tabs": [
      {
        "cwd": "/Users/yn/.config/nvim",
        "cursor": null,
        "selected": [],
        "sort": { "by": "natural", ... },
        "linemode": "...",
        "show_hidden": false
      }
    ]
  }
}
```

autosession の keymap (`q`) がまだ有効なので、Manager.quit フックと autosession の save-and-quit が両方走る。JSON が両方書かれれば OK。

- [ ] **Step 8: 別 launch cwd でエントリが追加されることを確認**

Run: `cd ~ && yazi` → `q` 終了
Run: `cat ~/.local/state/yazi/persist-by-launch.json | python3 -m json.tool`
Expected: `/Users/yn/.config/nvim` と `/Users/yn` の 2 つのキーが並ぶこと

- [ ] **Step 9: Commit**

```bash
git add dot_config/yazi/init.lua
git commit -m "feat(yazi): persist state to JSON on Manager.quit"
```

---

## Task 4: 復元関数を実装 (単一タブ、cwd + sort + linemode + hidden のみ)

**目的:** 起動時に JSON から launch cwd に対応するエントリを読み、単一タブで cwd/sort/linemode/hidden を復元する。cursor / selection / 多タブは後続。

**Files:**
- Modify: `dot_config/yazi/init.lua`

**Interfaces:**
- Consumes: `persist.state_file`, `persist.launch_cwd`, `json_decode`, `read_file` (Task 3)
- Produces:
  - `persist:restore()` — JSON を読んで単一タブの cwd/sort/linemode/hidden を emit で復元
  - `persist.restored` フラグで多重発火を防ぐ

- [ ] **Step 1: 手動検証手順を書き出す (先に定義)**

- yazi を `~/.config/nvim` から起動
- 適当な子ディレクトリ (例: `lua/`) に潜る
- sort を変更 (例: `,m` で mtime — 現在の autosession keymap では存在しないかもしれないので default キー `.` で hidden toggle でも可)
- `q` で終了
- 再度 `cd ~/.config/nvim && yazi` で起動
- 期待: 起動時に `lua/` に既に居る + sort/hidden の変更が反映されている

- [ ] **Step 2: 復元シーケンス関数 (単一タブ版) を追加**

```lua
local function bool_to_hidden(b)
  if b then return "show" else return "hide" end
end

local apply_tab = ya.sync(function(_, tab_data)
  ya.emit("cd", { tab_data.cwd })
  ya.emit("sort", tab_data.sort)
  ya.emit("linemode", { tab_data.linemode })
  ya.emit("hidden", { bool_to_hidden(tab_data.show_hidden) })
end)
```

`ya.sync` は state を第1引数に受けるため、data を第2引数として渡す実装:

```lua
local apply_tab = ya.sync(function(_, tab_data)
  ya.emit("cd", { tab_data.cwd })
  ya.emit("sort", tab_data.sort)
  ya.emit("linemode", { tab_data.linemode })
  ya.emit("hidden", { tab_data.show_hidden and "show" or "hide" })
end)
```

- [ ] **Step 3: persist:restore() を実装**

```lua
function persist:restore()
  if self.restored then return end
  self.restored = true
  if not self.launch_cwd then return end
  local content = read_file(self.state_file)
  if not content then return end
  local all = json_decode(content)
  if type(all) ~= "table" then return end
  local entry = all[self.launch_cwd]
  if type(entry) ~= "table" or type(entry.tabs) ~= "table" or #entry.tabs == 0 then
    return
  end
  apply_tab(entry.tabs[1])
end
```

- [ ] **Step 4: setup で restore を呼ぶ**

`persist:setup()` を修正:

```lua
function persist:setup()
  local sync_launch_cwd = ya.sync(function()
    return tostring(cx.tabs[1].current.cwd)
  end)
  self.launch_cwd = sync_launch_cwd()
  ya.dbg("persist-by-launch: launch_cwd=" .. tostring(self.launch_cwd))

  if Manager and Manager.quit then
    local _quit = Manager.quit
    Manager.quit = function(self_mgr, job)
      self:save()
      return _quit(self_mgr, job)
    end
  end

  self:restore()
end
```

`self:save()` の `self` 参照が closure 内で正しく解決するか注意 (Lua の scope で確認)。

- [ ] **Step 5: 手動検証**

Run:
```bash
chezmoi apply ~/.config/yazi/init.lua
rm -f ~/.local/state/yazi/persist-by-launch.json
cd ~/.config/nvim && yazi
```

yazi 内で:
1. `.` (hidden toggle) — 隠しファイルを表示
2. 子ディレクトリ `lua/` に入る
3. `q` で終了

再起動:
```bash
cd ~/.config/nvim && yazi
```

Expected:
- 起動直後、`~/.config/nvim/lua` に居る
- 隠しファイルが表示されている

- [ ] **Step 6: fallback ケースの検証**

Run: `cd /tmp && yazi` (persist-by-launch.json に `/tmp` のエントリはない)
Expected: yazi は `/tmp` で普通に起動する。エラーなし。

Run: `echo 'garbage' > ~/.local/state/yazi/persist-by-launch.json && cd ~/.config/nvim && yazi`
Expected: yazi は `~/.config/nvim` で普通に起動する。破損 JSON は無視される。

- [ ] **Step 7: Commit**

```bash
git add dot_config/yazi/init.lua
git commit -m "feat(yazi): restore cwd/sort/linemode/hidden from persist store"
```

---

## Task 5: cursor 位置の復元を追加

**目的:** 前回ホバーしていたファイルにカーソルを合わせる。`reveal <cwd>/<cursor>` を使う (Task 1 の spike で仕様確認済み)。

**Files:**
- Modify: `dot_config/yazi/init.lua`

**Interfaces:**
- Consumes: `collect_state` (Task 3), `apply_tab` (Task 4)
- Produces:
  - `collect_state` が cursor フィールドに hovered ファイルの basename を書く
  - `apply_tab` が cursor 非 null 時に `reveal` を emit する

- [ ] **Step 1: 手動検証手順を書き出す (先に定義)**

- `cd ~/.config/nvim && yazi` 起動
- `lua/` に入る
- 適当なファイル (例: `options.lua`) にカーソルを合わせる
- `q` 終了
- 再起動 → `lua/options.lua` にカーソルが合っている状態で起動される

- [ ] **Step 2: collect_state で cursor を収集**

`collect_state` の tab 情報収集ループを修正:

```lua
local collect_state = ya.sync(function()
  local tabs = cx.tabs
  local session = { active = tabs.idx, tabs = {} }
  for i, tab in ipairs(tabs) do
    local hovered = tab.current.hovered
    local cursor_name = nil
    if hovered then
      cursor_name = tostring(hovered.url):match("([^/]+)$")
    end
    session.tabs[i] = {
      cwd = tostring(tab.current.cwd),
      cursor = cursor_name,
      selected = {},
      sort = {
        by = tab.pref.sort_by,
        reverse = tab.pref.sort_reverse,
        dir_first = tab.pref.sort_dir_first,
        sensitive = tab.pref.sort_sensitive,
        translit = tab.pref.sort_translit,
      },
      linemode = tab.pref.linemode,
      show_hidden = tab.pref.show_hidden,
    }
  end
  return session
end)
```

- [ ] **Step 3: apply_tab で cursor を復元**

Task 1 の spike で確認した `reveal` の引数仕様に応じて実装。基本形:

```lua
local apply_tab = ya.sync(function(_, tab_data)
  ya.emit("cd", { tab_data.cwd })
  ya.emit("sort", tab_data.sort)
  ya.emit("linemode", { tab_data.linemode })
  ya.emit("hidden", { tab_data.show_hidden and "show" or "hide" })
  if tab_data.cursor then
    ya.emit("reveal", { tab_data.cwd .. "/" .. tab_data.cursor })
  end
end)
```

`reveal` が `--no-dummy` などのフラグを要求する場合は spike ノートに従って調整。

- [ ] **Step 4: 手動検証**

Run:
```bash
chezmoi apply ~/.config/yazi/init.lua
rm -f ~/.local/state/yazi/persist-by-launch.json
cd ~/.config/nvim && yazi
```

yazi 内で:
1. `lua/` に入る
2. 特定のファイル (例: `options.lua`) にカーソル移動
3. `q` 終了

再起動:
```bash
cd ~/.config/nvim && yazi
```

Expected: `~/.config/nvim/lua/options.lua` にカーソルが合った状態で起動

- [ ] **Step 5: fallback 検証 (対象ファイルなし)**

Run:
```bash
cd ~/.config/nvim && yazi
```

- 存在するファイルを touch: `touch /tmp/yazi-test-file && cd /tmp && yazi`
- `yazi-test-file` にカーソル → `q`
- ターミナルで `rm /tmp/yazi-test-file`
- `cd /tmp && yazi`
Expected: エラーなし、`/tmp` の適当な位置で起動 (reveal 対象が無いので何も起きない)

- [ ] **Step 6: Commit**

```bash
git add dot_config/yazi/init.lua
git commit -m "feat(yazi): restore hovered cursor position via reveal"
```

---

## Task 6: 選択集合 (multi-select) の復元を追加

**目的:** `space` で選択したファイル群を復元する。Task 1 の spike で `toggle` が URL 引数を取れるか / bulk API があるかを確認済みの前提。

**Files:**
- Modify: `dot_config/yazi/init.lua`

**Interfaces:**
- Consumes: `collect_state` (Task 5), `apply_tab` (Task 5)
- Produces:
  - `collect_state` が `selected` フィールドに URL 配列を書く
  - `apply_tab` が `selected` の各 URL に `reveal` + `toggle` を発火

- [ ] **Step 1: 手動検証手順を書き出す (先に定義)**

- yazi 起動 → 3 ファイルを `space` で選択 → `q`
- 再起動 → 同じ 3 ファイルが選択状態

- [ ] **Step 2: collect_state で selected を収集**

`collect_state` の tab loop 内、`cursor_name` 直後に追加:

```lua
local selected = {}
for _, url in ipairs(tab.selected) do
  selected[#selected + 1] = tostring(url)
end
```

そして `session.tabs[i].selected = selected` に置き換え。

`tab.selected` の実際のフィールド名は Task 1 の spike で確定させる (`cx.active.selected` かもしれない)。

- [ ] **Step 3: apply_tab で選択を復元**

Task 1 の spike で `toggle --urls=<...>` などの bulk API があるとわかれば単純化。無ければ per-URL 反復:

```lua
local apply_tab = ya.sync(function(_, tab_data)
  ya.emit("cd", { tab_data.cwd })
  ya.emit("sort", tab_data.sort)
  ya.emit("linemode", { tab_data.linemode })
  ya.emit("hidden", { tab_data.show_hidden and "show" or "hide" })
  if tab_data.cursor then
    ya.emit("reveal", { tab_data.cwd .. "/" .. tab_data.cursor })
  end
  for _, url in ipairs(tab_data.selected or {}) do
    ya.emit("reveal", { url })
    ya.emit("toggle", { "--state=on" })
  end
end)
```

`toggle` の実際の引数 (state フラグの有無) は spike で確定。

- [ ] **Step 4: 手動検証**

Run:
```bash
chezmoi apply ~/.config/yazi/init.lua
rm -f ~/.local/state/yazi/persist-by-launch.json
cd ~/.config/nvim && yazi
```

yazi 内で:
1. 3 つのファイル (例: `init.lua`, `lazy-lock.json`, `stylua.toml`) を `space` で選択
2. `q` 終了

再起動:
```bash
cd ~/.config/nvim && yazi
```

Expected: 3 ファイルが選択状態 (視覚的にハイライトされる)

- [ ] **Step 5: fallback 検証 (選択ファイルの一部欠損)**

- `touch /tmp/yazi-a /tmp/yazi-b`
- `cd /tmp && yazi` → 両方 `space` 選択 → `q`
- `rm /tmp/yazi-a`
- `cd /tmp && yazi`

Expected: `yazi-b` のみ選択状態。`yazi-a` はスキップされる。エラーなし。

- [ ] **Step 6: Commit**

```bash
git add dot_config/yazi/init.lua
git commit -m "feat(yazi): restore multi-select set on startup"
```

---

## Task 7: 多タブ復元を追加

**目的:** 複数タブの構成 (各タブの cwd/cursor/selected/prefs + active タブ) を復元する。

**Files:**
- Modify: `dot_config/yazi/init.lua`

**Interfaces:**
- Consumes: `apply_tab` (Task 6), `collect_state` (Task 6)
- Produces:
  - `persist:restore()` がタブ数を調整し、各タブごとに `apply_tab` を呼び、active タブに切り替える

- [ ] **Step 1: 手動検証手順を書き出す (先に定義)**

- yazi 起動 → `t` で新規タブを 2 つ作成 → 各タブで別ディレクトリへ移動 → 2 番目タブをアクティブに → `q`
- 再起動 → 3 タブ構成 + 2 番目がアクティブ

- [ ] **Step 2: タブ数調整関数を追加**

```lua
local get_tab_count = ya.sync(function()
  return #cx.tabs
end)

local adjust_tab_count = ya.sync(function(_, target)
  local current = #cx.tabs
  while current < target do
    ya.emit("tab_create", {})
    current = current + 1
  end
  while current > target do
    ya.emit("tab_close", { current - 1 })
    current = current - 1
  end
end)

local switch_tab = ya.sync(function(_, idx)
  ya.emit("tab_switch", { idx })
end)
```

`tab_create` の引数と `tab_close` のインデックス (0-based/1-based) は Task 1 spike で確定。

- [ ] **Step 3: persist:restore() を多タブ対応に書き換え**

```lua
function persist:restore()
  if self.restored then return end
  self.restored = true
  if not self.launch_cwd then return end
  local content = read_file(self.state_file)
  if not content then return end
  local all = json_decode(content)
  if type(all) ~= "table" then return end
  local entry = all[self.launch_cwd]
  if type(entry) ~= "table" or type(entry.tabs) ~= "table" or #entry.tabs == 0 then
    return
  end

  adjust_tab_count(#entry.tabs)

  for i, tab_data in ipairs(entry.tabs) do
    switch_tab(i - 1)
    apply_tab(tab_data)
  end

  local active_idx = (tonumber(entry.active) or 1) - 1
  switch_tab(active_idx)
end
```

- [ ] **Step 4: 手動検証**

Run:
```bash
chezmoi apply ~/.config/yazi/init.lua
rm -f ~/.local/state/yazi/persist-by-launch.json
cd ~/.config/nvim && yazi
```

yazi 内で:
1. `t` で新規タブを作成 → `cd ~/.local/share/chezmoi`
2. `t` でもう1つ新規タブ → `cd /tmp`
3. `1` (or Tab key) でタブ 2 番目 (chezmoi) をアクティブに
4. `q` 終了

再起動:
```bash
cd ~/.config/nvim && yazi
```

Expected:
- 3 タブが並んでいる (`~/.config/nvim`, `~/.local/share/chezmoi`, `/tmp`)
- 2 番目タブ (`chezmoi`) がアクティブ

- [ ] **Step 5: JSON の中身を確認**

Run: `cat ~/.local/state/yazi/persist-by-launch.json | python3 -m json.tool`
Expected: `tabs` 配列が 3 要素、`active` が 2

- [ ] **Step 6: Commit**

```bash
git add dot_config/yazi/init.lua
git commit -m "feat(yazi): restore multi-tab layout with active tab"
```

---

## Task 8: autosession と pref-by-location を撤去

**目的:** 旧プラグイン (autosession, pref-by-location) と autosession の `q` keymap を削除する。persist-by-launch が単独で動く状態にする。

**Files:**
- Modify: `dot_config/yazi/init.lua`
- Modify: `dot_config/yazi/keymap.toml`
- (chezmoi 管理外) `~/.config/yazi/package.toml`, `~/.config/yazi/plugins/autosession.yazi/`, `~/.config/yazi/plugins/pref-by-location.yazi/`

**Interfaces:**
- Consumes: 全 Task の実装
- Produces:
  - `init.lua` から `require("autosession"):setup()` を削除
  - `keymap.toml` から autosession の `q` バインディングを削除 (デフォルトの `q` = quit に戻す)
  - `~/.config/yazi/plugins/` から autosession / pref-by-location を削除

- [ ] **Step 1: init.lua から autosession の require を削除**

`dot_config/yazi/init.lua` の先頭行を削除:

Before:
```lua
-- ~/.config/yazi/init.lua

require("autosession"):setup()

-- persist-by-launch: launch cwd 単位でセッションを保存/復元する
```

After:
```lua
-- ~/.config/yazi/init.lua

-- persist-by-launch: launch cwd 単位でセッションを保存/復元する
```

- [ ] **Step 2: keymap.toml から autosession の q バインディングを削除**

`dot_config/yazi/keymap.toml` の内容を確認:

Run: `cat ~/.local/share/chezmoi/dot_config/yazi/keymap.toml`
Expected:
```toml
# ~/.config/yazi/keymap.toml
[mgr]
prepend_keymap = [
    { on = [ "q" ], run = "plugin autosession -- save-and-quit", desc = "Save session and quit" },
]
```

これを空の prepend_keymap に:
```toml
# ~/.config/yazi/keymap.toml
[mgr]
prepend_keymap = []
```

Manager.quit フック側で保存するので、デフォルトの `q` = `quit` コマンドで問題ない。

- [ ] **Step 3: chezmoi apply**

Run: `chezmoi apply ~/.config/yazi/init.lua ~/.config/yazi/keymap.toml`

- [ ] **Step 4: package.toml から旧プラグインエントリを削除 (手動)**

`~/.config/yazi/package.toml` を編集。以下の 2 ブロックを削除:

```toml
[[plugin.deps]]
use = "barbanevosa/autosession"
rev = "..."
hash = "..."

[[plugin.deps]]
use = "boydaihungst/pref-by-location"
rev = "..."
hash = "..."
```

`piper` エントリと `[flavor]` は残す。

- [ ] **Step 5: プラグインディレクトリを削除**

Run:
```bash
rm -rf ~/.config/yazi/plugins/autosession.yazi
rm -rf ~/.config/yazi/plugins/pref-by-location.yazi
ls ~/.config/yazi/plugins/
```
Expected: `piper.yazi` のみ残る

- [ ] **Step 6: 統合手動検証**

Run:
```bash
rm -f ~/.local/state/yazi/persist-by-launch.json
cd ~/.config/nvim && yazi
```

yazi 内で:
1. 子ディレクトリに移動 + カーソル位置変更 + ファイル選択 + タブ追加
2. `q` 終了

再起動:
```bash
cd ~/.config/nvim && yazi
```

Expected:
- 前回の全 state が復元される
- 旧プラグインなしで動作
- `q` のデフォルト挙動 (通常 quit) が persist-by-launch の保存を経由する

- [ ] **Step 7: yazi の debug ログを確認**

Run: `grep persist ~/.local/state/yazi/yazi.log | tail -10`
Expected: `persist-by-launch: launch_cwd=...` の行、エラーメッセージなし

- [ ] **Step 8: 別 launch cwd の独立性を確認**

Run:
```bash
cd /tmp && yazi  # 別の cwd
```
Expected: `~/.config/nvim` とは別の state で起動する (エントリ無しなら空/デフォルト)

Run: `cat ~/.local/state/yazi/persist-by-launch.json | python3 -m json.tool | head -20`
Expected: 複数の launch cwd キーが並ぶ

- [ ] **Step 9: Commit**

```bash
git add dot_config/yazi/init.lua dot_config/yazi/keymap.toml
git commit -m "feat(yazi): switch to persist-by-launch, remove autosession/pref-by-location"
```

- [ ] **Step 10: package.toml の変更を chezmoi 管理に取り込むか判断**

`~/.config/yazi/package.toml` は現状 chezmoi 管理外。他の init.lua/keymap.toml は chezmoi 管理下なので、package.toml も管理下に置くと再現性が上がる。ただしこれは本プランのスコープ外の判断。ユーザーに確認するか、別チケットに切り出す。

---

## Self-Review

**Spec coverage:**
- ✅ launch cwd をキーにした保存/復元 → Task 2〜7
- ✅ cwd / cursor / selected / sort / linemode / show_hidden → Task 3 (cwd/sort/linemode/hidden), Task 5 (cursor), Task 6 (selected)
- ✅ 多タブ + active タブ → Task 7
- ✅ JSON 保存先 XDG_STATE_HOME → Task 3
- ✅ Manager.quit フック → Task 3 + spike (Task 1)
- ✅ エラー処理 (JSON 破損 / cwd 消失 / ファイル欠損) → Task 4/5/6 の fallback 検証
- ✅ init.lua 直書き → 全 Task
- ✅ autosession と pref-by-location の撤去 → Task 8
- ✅ 技術リスク (§技術リスクと検証項目) → Task 1 の spike で潰す

**Placeholder scan:**
- Task 3 Step 2 に「Task 1 の spike 結果に応じてこのブロックを埋める」— これは placeholder に見えるが、実際には spike 結果に応じた分岐実装であり、`ya.json_encode` が使える場合の完全実装は同ステップで提示済み。手書きが必要な場合のみ実装で書き足す。許容範囲。

**Type consistency:**
- `collect_state` → `apply_tab` の受け渡し: `{ cwd, cursor, selected, sort, linemode, show_hidden }` で Task 3→5→6 で一貫
- `session.tabs[i]` と `entry.tabs[i]` は同一構造
- `tabs.idx` と `entry.active` は 1-indexed、`tab_switch` 引数は 0-indexed で `-1` 変換一貫
- `tab.pref.*` フィールド名は autosession の実装と一致 (sort_by / sort_reverse / sort_dir_first / sort_sensitive / sort_translit / linemode / show_hidden)

---
