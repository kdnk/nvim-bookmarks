# nvim-bookmarks Testing

このディレクトリには、nvim-bookmarksプラグインの包括的なテストが含まれています。

## テストフレームワーク

- **plenary.nvim**: Neovim用のテストフレームワーク（bustedスタイル）
- **luassert**: モック・スタブ・アサーション機能
- **neotest**: オプション - neotestでも実行可能

## ディレクトリ構造

```
tests/
├── minimal_init.lua              # テスト用の最小Neovim設定
├── helpers/
│   ├── init.lua                  # テストヘルパー関数
│   ├── mock.lua                  # Neovim APIモック（luassert stub使用）
│   └── fixtures.lua              # テストデータジェネレーター
├── unit/                         # ユニットテスト
│   ├── bookmark_spec.lua         # ブックマーク状態管理
│   ├── jump_spec.lua             # ナビゲーションロジック
│   ├── persist_spec.lua          # 永続化機能
│   ├── sync_spec.lua             # 同期ロジック
│   ├── extmark_spec.lua          # 位置追跡
│   ├── sign_spec.lua             # ビジュアル表示
│   ├── config_spec.lua           # 設定管理
│   ├── file_spec.lua             # ファイルI/O
│   └── core/
│       └── lua_spec.lua          # ユーティリティ関数
└── integration/                  # 統合テスト（今後追加予定）
```

## テストの実行

### 必須条件

- Neovim (stable または nightly)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [just](https://github.com/casey/just) (オプション - コマンドランナー)

### plenary.nvimのインストール

```bash
# lazy.nvimを使用している場合、自動的にインストールされます
# 手動インストール:
mkdir -p ~/.local/share/nvim/site/pack/vendor/start
git clone --depth 1 https://github.com/nvim-lua/plenary.nvim \
  ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim
```

### テスト実行方法

#### 1. justを使用（推奨）

```bash
# 全テストを実行
just test

# ユニットテストのみ
just test-unit

# 統合テストのみ（今後追加予定）
just test-integration

# 特定のテストファイルを実行
just test-file tests/unit/bookmark_spec.lua
```

#### 2. nvimコマンドを直接使用

```bash
# 全ユニットテストを実行
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/unit/ { minimal_init = 'tests/minimal_init.lua' }"

# 特定のテストファイルを実行
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedFile tests/unit/bookmark_spec.lua"
```

#### 3. Neovim内から実行

```vim
" Neovimを開いて
:PlenaryBustedDirectory tests/unit/
" または特定のファイル
:PlenaryBustedFile tests/unit/bookmark_spec.lua
```

#### 4. neotestを使用（オプション）

neotest + neotest-plenaryがインストールされている場合:

```lua
-- Neovim設定
require("neotest").setup({
  adapters = {
    require("neotest-plenary"),
  },
})
```

その後、`:Neotest run`などのコマンドでテストを実行できます。

## テストカバレッジ

現在のテストカバレッジ:

| モジュール | テスト数 | 状態 |
|-----------|---------|------|
| core/lua.lua | 34 | ✅ |
| bookmark.lua | 16 | ✅ |
| jump.lua | 14 | ✅ |
| extmark.lua | 14 | ✅ |
| persist.lua | 12 | ✅ |
| config.lua | 9 | ✅ |
| file.lua | 6 | ✅ |
| sign.lua | 5 | ✅ |
| sync.lua | 3 | ✅ |
| **合計** | **113** | **✅** |

## CI/CD

GitHub Actionsで自動的にテストが実行されます:

- Neovim stable と nightly の両方でテスト
- Pull Request時に自動実行
- styluaによるコードフォーマットチェック

## テストの書き方

### 基本構造

```lua
describe("モジュール名", function()
  before_each(function()
    -- 各テスト前のセットアップ
  end)

  after_each(function()
    -- 各テスト後のクリーンアップ
  end)

  describe("機能名", function()
    it("should do something", function()
      -- テストコード
      assert.are.equal(expected, actual)
    end)
  end)
end)
```

### モックの使用

```lua
local mock = require("tests.helpers.mock")
local stub = require("luassert.stub")

-- Neovim APIをモック
mock.setup_vim_api()
mock.set_buf_name(1, "/test/file.lua")

-- 関数をstub
stub(vim.fn, "sign_place")

-- アサーション
assert.stub(vim.fn.sign_place).was_called()
```

## トラブルシューティング

### plenary.nvimが見つからない

```
Error: module 'plenary' not found
```

→ plenary.nvimをインストールしてください（上記参照）

### テストが失敗する

1. Neovimのバージョンを確認: `nvim --version`
2. モジュールキャッシュをクリア: `:lua package.loaded['bookmarks'] = nil`
3. 最新のmainブランチを使用していることを確認

## 参考リンク

- [plenary.nvim テストドキュメント](https://github.com/nvim-lua/plenary.nvim/blob/master/TESTS_README.md)
- [luassert ドキュメント](https://lunarmodules.github.io/luassert/)
- [neotest](https://github.com/nvim-neotest/neotest)
