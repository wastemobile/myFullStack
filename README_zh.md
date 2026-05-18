# Full Stack HQ

*🌏 [English README.md](./README.md)*

> 為 TypeScript-first 全端工作流設計的 AI 編碼配置集。
> 單一權威規則檔（`AGENTS.md`），可被任何現代 AI coding agent 讀取。

靈感來自 [sabahattink/antigravity-fullstack-hq](https://github.com/sabahattink/antigravity-fullstack-hq) — 為 Claude Code 改寫、改用 Astro/Svelte/SQLite 技術棧，並精簡複雜度。

---

## 技術棧

- **前端** — Astro 5+、Svelte 5（runes）、Tailwind CSS v4、TypeScript 5+
- **後端** — NestJS、Node.js 24+、BullMQ、Redis
- **資料庫** — SQLite 3（dev/test + 小型 prod）、PostgreSQL 16+（中大型 prod）、Prisma 6+
- **認證** — JWT + refresh token 輪替
- **測試** — Vitest、Jest、Playwright
- **基礎設施** — Rocky Linux / Ubuntu、Docker（優先用 Docker Compose）、Caddy 2

引擎切換判準（活躍使用者數、資料量、部署拓樸）記錄於 `AGENTS.md` §3。

---

## 給 AI Agents 的指引

若你是 AI coding agent 並被指向這個 repo：

1. **先讀 [`AGENTS.md`](./AGENTS.md)** — 權威規則集（權限工作流、程式碼風格、技術棧規則）。
2. **再讀 [`KNOWLEDGE.md`](./KNOWLEDGE.md)** — 整理過的「官方」AI / MCP / agent 入口清單（Svelte、Astro、Prisma、Playwright、Redis、Docker…），用來接上 MCP server 與 skills，**不要**追逐第三方外掛。
3. **再讀 [`skills/`](./skills/)** — 沒有官方 MCP（或在使用官方 MCP 之前）所需的具體操作 know-how：TypeScript patterns、Tailwind、Prisma 工作流、Docker、git 指令、NestJS 鷹架。目的是讓不同 agent / 不同等級模型有一致基線。

各工具的入口檔指向同一份內容：

| Agent | 入口檔 | 解析方式 |
|---|---|---|
| Claude Code | `CLAUDE.md` | 一行檔：`@AGENTS.md`（Claude Code include 語法） |
| OpenAI Codex | `AGENTS.md` | 直接讀 |
| OpenCode (sst) | `AGENTS.md` | 直接讀 |
| Hermes Agent | `AGENTS.md` | 直接讀 |
| 其他 [agents.md](https://agents.md) 相容工具 | `AGENTS.md` | 直接讀 |

**不要把規則複製或 fork 到 per-agent 的檔案。** 只更新 `AGENTS.md`。

---

## Repo 目錄結構

```
.
├── AGENTS.md              # 權威技術棧與風格偏好 — 從這裡開始
├── KNOWLEDGE.md           # 各技術棧元件的官方 AI/MCP 入口
├── skills/                # 操作 know-how（TS、Tailwind、Prisma、Docker…）
├── CLAUDE.md              # Claude Code 入口（include AGENTS.md）
├── .mcp.json              # 專案範疇的 MCP servers（Claude Code 會自動載入）
├── README.md              # 英文版（你正在讀繁中版 README_zh.md）
└── .claude/               # Claude Code 專屬擴充（其他 agent 可選）
    └── agents/            # Subagent 定義
        ├── frontend-specialist.md
        ├── backend-specialist.md
        ├── database-specialist.md
        └── code-reviewer.md
```

`.claude/agents/` 是 Claude Code 慣例。其他 agent 也能以純 Markdown 的角色描述方式閱讀。

**不綁定工作流（workflow-agnostic）。** 規劃、除錯、測試等工作流來自各 agent 自己的命令（例如 Claude Code 內建 `/plan`）或另外安裝的 skills。這個 repo 只描述「**用什麼技術棧、用什麼規範**」，不管「**怎麼跑工作流**」。

### Dev-only 檔案（用來維護這個 repo 自己，不會被安裝到目標專案）

repo 內額外有幾個檔案用於維護 `/use-mystack` 流程。bootstrap.sh、template-mirror hook、`/sync-template` 都會**排除**這些檔案 — 但 clone 下來會看到：

| 路徑 | 用途 |
|---|---|
| `bootstrap.sh` | 新機器一行 `curl \| bash` 安裝 `/use-mystack` skill |
| `bootstrap/use-mystack.md` | `/use-mystack` skill 的權威副本（與 `~/.claude/commands/use-mystack.md` 雙胞胎同步）|
| `.claude/commands/sync-template.md` | 手動的專案範疇 slash command，把這個 repo 同步到本機 template 快取 |
| `.claude/hooks/template-mirror.sh` | PostToolUse hook，編輯源檔後自動同步 → 本機 template 快取 + skill 雙胞胎 |
| `.claude/settings.json` | 註冊上面那個 PostToolUse hook |

---

## 安裝到專案 — 手動路徑

> 適用於 **非 Claude Code 的 agents**（Codex、OpenCode、Hermes），或偏好明確逐檔複製的人。
> Claude Code 使用者有更快的路徑 — 見下方 [新機器設定](#新機器設定--use-mystack-bootstrap)。

手動複製檔案，明確掌握每個檔案落到哪裡：

```bash
# 在你想套用規則的專案根目錄：
PROJECT_DIR="$(pwd)"
TMP_DIR="$(mktemp -d)"

git clone --depth 1 https://github.com/wastemobile/myFullStack.git "$TMP_DIR/fullStack"

cp "$TMP_DIR/fullStack/AGENTS.md"    "$PROJECT_DIR/AGENTS.md"
cp "$TMP_DIR/fullStack/KNOWLEDGE.md" "$PROJECT_DIR/KNOWLEDGE.md"
cp "$TMP_DIR/fullStack/CLAUDE.md"    "$PROJECT_DIR/CLAUDE.md"
cp "$TMP_DIR/fullStack/.mcp.json"    "$PROJECT_DIR/.mcp.json"
cp -r "$TMP_DIR/fullStack/skills"           "$PROJECT_DIR/skills"
mkdir -p "$PROJECT_DIR/.claude"
cp -r "$TMP_DIR/fullStack/.claude/agents"   "$PROJECT_DIR/.claude/agents"

rm -rf "$TMP_DIR"
```

> 只複製 `.claude/agents/` — `.claude/commands/`、`.claude/hooks/`、`.claude/settings.json` 是本 repo 的 dev-only 檔案，**不可**進入目標專案。

接著 commit：

```bash
git add AGENTS.md KNOWLEDGE.md CLAUDE.md .mcp.json skills/ .claude/agents/
git commit -m "chore: adopt Full Stack HQ agent rules"
```

### 加入 `.gitignore`

`.claude/settings.local.json` 是 per-machine 的權限狀態，不應被 commit：

```
.claude/settings.local.json
```

### 驗證

打開新的 agent session，請它**用三點摘要規則**。配置正確的 agent 會提到：permission-first 工作流、Astro/Svelte/SQLite 技術棧、approval 關鍵字（`PLAN APPROVED`、`IMPLEMENTATION APPROVED`、`PROCEED`、`DO IT`）。

Claude Code 也要檢查 MCP servers 是否載入：

```
/mcp
```

應看到 `svelte`、`astro-docs`、`context7` 三個都連上。第一次執行會跳信任提示，按下批准。

非 Claude Code 的 agent（Codex、OpenCode、Hermes），請參考 [`KNOWLEDGE.md`](./KNOWLEDGE.md#equivalent-for-other-agents) 中各 agent 對應的 MCP 安裝指令。

---

## 新機器設定 — `/use-mystack` Bootstrap

> **Claude Code 路徑（推薦）。** 一次性設定後，`/use-mystack` 之後每次安裝都會自我更新並偵測偏移。若你不使用 Claude Code，請看上方 [安裝到專案 — 手動路徑](#安裝到專案--手動路徑)。

一行指令搞定：

```bash
curl -fsSL https://raw.githubusercontent.com/wastemobile/myFullStack/main/bootstrap.sh | bash
```

它做三件事：

1. 把這個 repo `git clone` 到 `~/projects/myFullStack`（已存在則 `git pull`）
2. 用 `rsync` 把 repo 同步到 `~/.claude/templates/fullStack/` — 安裝來源快取
3. 複製 `bootstrap/use-mystack.md` 到 `~/.claude/commands/use-mystack.md` — skill 檔本身

跑完後重啟 Claude Code（或 `/reload-plugins`），然後到任何專案執行：

```
/use-mystack
```

這個 skill 會：

- **安裝前檢查 GitHub 是否有更新**（Step 0 preflight）。本地 repo 落後時詢問是否 `git pull` 並重新同步 template；skill 本身有偏移時也會詢問是否更新。
- **對既有專案 smart-merge**：空目錄寫入完整副本；既有專案則在 `<!-- BEGIN: full-stack-hq -->` 標記區塊內附加偏好（idempotent — 重複執行不會有副作用）。
- **以 semver tag 偵測偏移**：標記內嵌入版本號（如 `v1.0.0`）。下次執行會顯示「installed v1.0.0, template v1.2.0（落後 N commits）」，附 GitHub Release notes 連結，建議用 `/use-mystack --refresh`。

可用旗標：`--refresh`（重寫標記區塊）、`--dry-run`（只預覽）、`--skip-update`（用快取，不檢查 GitHub）。

### 版本規則

本 repo 用 [SemVer](https://semver.org/) git tag + [GitHub Releases](https://github.com/wastemobile/myFullStack/releases)。對偏好類 repo 的語意慣例：

- **PATCH**（`v1.0.X`）— typo、純文件修改，不影響 agent 行為
- **MINOR**（`v1.X.0`）— 新規則、新 skill、新 MCP 推薦（向下相容）
- **MAJOR**（`vX.0.0`）— 移除規則、章節編號重整、會明顯改變 agent 行為的變更

完整變更紀錄請看 [github.com/wastemobile/myFullStack/releases](https://github.com/wastemobile/myFullStack/releases)。

### 維護本機 mirror

在本地編輯這個 repo 時，`template-mirror` PostToolUse hook（定義於 `.claude/hooks/template-mirror.sh`）會自動把 `AGENTS.md`、`KNOWLEDGE.md`、`CLAUDE.md`、`.mcp.json`、`.gitignore`、`skills/**`、`.claude/agents/**` 的變更同步到 `~/.claude/templates/fullStack/`。同時也會把 `bootstrap/use-mystack.md` → `~/.claude/commands/use-mystack.md` 同步，讓 skill 雙胞胎保持一致。

批次改動或 hook 暫時關閉時，可手動執行 `/sync-template`（會先 dry-run 預覽再確認）。

---

## 快速啟動：開新專案

完成上面的 bootstrap 後，config 檔已就位，但**還沒任何鷹架程式碼**。要啟動：

1. 用你的 agent 打開該目錄（`claude`、`codex`、`opencode`…）。它會自動載入 `AGENTS.md`（Claude Code 透過 `CLAUDE.md → @AGENTS.md`）。Claude Code 第一次跑會詢問是否信任專案範疇的 MCP，按下批准。

2. **第一句訊息貼這個**（agent-agnostic）：

   > 我想做 **[一句話描述，例如「給我自己用的記帳工具，單人、本機」]**。請依此 repo 的技術棧基線。
   >
   > 先輸出 AGENTS.md §0 規定的 Session Start Check。然後提出鷹架計畫：目錄結構、初始化指令（`astro create`、`nest new`、`prisma init` 等）、以及任何根據 AGENTS.md §3 判準你建議偏離基線的選擇（例如 SQLite vs PostgreSQL）。寫任何 code 前先等我 `PLAN APPROVED`。

3. Agent 會回 `[Session Start Check]` 區塊，接著是鷹架計畫。檢視、調整、滿意後回 `PLAN APPROVED` — 它才會跑 init 指令。

4. 之後每個 feature 都走相同迴圈：描述 → `[Session Start Check]`（若是新 session）→ 規劃步（用 agent 自己的 `/plan` 命令、skill，或對話式提案）→ `PLAN APPROVED` → 實作 → 審查。單檔 ≤ 30 行的修改可直接用 `IMPLEMENTATION APPROVED`。

### 為什麼這個設計有效

- **AGENTS.md §0** 強制 agent 動手前先宣告它的理解 — 提早抓到技術棧不符或跳過 skill 的問題。
- **AGENTS.md §1 Permission-First** 防止 agent 收到一句話請求就直接寫多檔鷹架 — 必須有明確 approval 關鍵字。
- **`.mcp.json`** 自動接上 Svelte / Astro 即時文件，agent 不用瞎猜訓練資料。

若 agent 跳過 Session Start Check 或沒拿到 `PLAN APPROVED` 就動筆，就是 regression — 用這句重新提示：*「請嚴格遵循 AGENTS.md §0 與 §1。」*

---

## 客製化

- **不同技術棧？** 編輯 `AGENTS.md` §3（Tech Stack）和 §4（Code Style），然後更新 `KNOWLEDGE.md` 對應的官方 AI 入口，並替換/移除 `skills/` 受影響的檔案。
- **想加減 subagent？** 在 `.claude/agents/` 增刪檔案。`AGENTS.md` §2 表格要對應更新。
- **要新的操作 skill？** 在 `skills/` 加檔，YAML frontmatter 需含 `name`、`description`，並登錄到 `AGENTS.md` §11。
- **想要 slash command 或工作流自動化？** 透過你 agent 自己的機制安裝（Claude Code skills/commands、Codex prompts 等）— 這個 repo 刻意保持 workflow-agnostic，讓同一份規則能交付到任何 agent。
- **上游有新的官方 MCP / Skill / Subagent？** 加到 `KNOWLEDGE.md` 並更新「Last verified」日期。

權威來源：

- `AGENTS.md` — 規則
- `KNOWLEDGE.md` — 外部 AI 整合
- `skills/` — 操作 know-how（工具 / 套件 / 語言）

---

## 授權

延續上游 MIT 授權精神。自由使用。
