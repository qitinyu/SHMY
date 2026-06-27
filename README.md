
## 项目介绍
### 功能特性

- **用户系统**: GitHub OAuth 第三方登录为主,辅以QQ号注册/邮箱注册登录
- **评论系统**: 无限制嵌套回复、Markdown 语法支持、评论折叠/展开
- **管理后台**: 密码保护、留言批量管理（删除/置顶/精华）、用户管理、邮箱通知设置
- **安全性**: Cookie 会话、管理员独立会话、密码哈希
- **UI 设计**: 响应式布局、shadcn/ui 组件库、深色模式支持
- **存储**: 纯 JSON 文件存储，无需数据库

---

### 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Next.js | 16 (App Router) | 全栈框架 |
| React | 19 | UI 渲染 |
| TypeScript | 5 | 类型安全 |
| Tailwind CSS | 4 | 样式系统 |
| shadcn/ui | new-york | UI 组件库 |
| Zustand | 5 | 状态管理 |
| react-markdown | 10 | Markdown 渲染 |
| date-fns | 4 | 时间格式化 |

---

### 项目结构

```
yuamli/
├── src/                          # 源代码
│   ├── app/                      # Next.js App Router
│   │   ├── page.tsx              # 主页面
│   │   ├── layout.tsx            # 根布局
│   │   ├── globals.css           # 全局样式
│   │   └── api/                  # API 路由
│   │       ├── auth/
│   │       │   ├── login/        # 登录
│   │       │   ├── register/     # 注册
│   │       │   ├── session/      # 会话管理
│   │       │   └── github/       # GitHub OAuth
│   │       │       ├── route.ts          # Token 交换
│   │       │       └── callback/route.ts # 授权回调
│   │       ├── comments/
│   │       │   ├── route.ts      # 留言列表( GET ) / 新建( POST )
│   │       │   └── [id]/route.ts # 编辑( PUT ) / 删除( DELETE )
│   │       └── admin/
│   │           ├── route.ts      # 管理员登录/数据
│   │           ├── notify/route.ts    # 通知设置
│   │           └── comments/route.ts  # 批量留言管理
│   ├── components/
│   │   ├── comment-system/       # 留言系统组件
│   │   │   ├── AuthModal.tsx     # 登录/注册弹窗
│   │   │   ├── CommentForm.tsx   # 留言编辑器
│   │   │   ├── CommentItem.tsx   # 单条留言（递归渲染）
│   │   │   ├── CommentList.tsx   # 留言列表 + 折叠
│   │   │   └── AdminPanel.tsx    # 后台管理面板
│   │   └── ui/                   # shadcn/ui 基础组件
│   ├── lib/
│   │   ├── storage.ts            # JSON 文件读写
│   │   ├── auth.ts               # 会话/密码工具
│   │   └── utils.ts              # 通用工具
│   ├── store/
│   │   └── use-comment-store.ts  # Zustand 全局状态
│   └── hooks/                    # React Hooks
├── data/                         # JSON 数据文件
│   ├── comments.json             # 留言数据
│   ├── users.json                # 用户数据
│   └── config.json               # 站点配置
├── public/                       # 静态资源
│   ├── logo.svg
│   └── robots.txt
├── .env.example                  # 环境变量模板
├── .gitignore                    # Git 忽略规则
├── package.json                  # 项目依赖
├── next.config.ts                # Next.js 配置
├── tsconfig.json                 # TypeScript 配置
├── tailwind.config.ts            # Tailwind 配置
├── postcss.config.mjs            # PostCSS 配置
├── components.json               # shadcn/ui 配置
└── Caddyfile                     # Caddy 反向代理配置（可选）
```

---
## 测试和部署
### 本地测试开发

```bash
# 1. 克隆仓库到本地文件夹
git clone https://github.com/Yuamli/Yuamli.git

# 2. 换至目标目录
cd Yuamli

# 3. 安装依赖
npm install
# 或 pnpm install / bun install

# 4. 配置环境变量
cp .env.example .env.local
# 编辑 .env.local 填入 GitHub OAuth 凭据

# 5. 启动开发服务器
npm run dev

# 6. 打开浏览器访问
# http://localhost:3000
```

### 构建生产版本(可选)

```bash
npm run build
npm start
```

---
### 本地环境变量配置(需获取 GitHub OAuth 凭据)
- **在项目根目录下创建 `.env.local` 文件，填入你的 GitHub OAuth 凭据：**
```eg
# .env.local 示例
NEXT_PUBLIC_GITHUB_CLIENT_ID=Ov23xxxxxxxUXe9Rjih
GITHUB_CLIENT_ID=Ov23xxxxxxxxxUXe9Rjih
GITHUB_CLIENT_SECRET=978c6xxxxxxxxxxxxxxxc3281002
```
- **如何获取 GitHub OAuth 凭据?**


>[!tip]
>这里的GitHub OAuth 建议创建开发和应用两份,否则就需要不停去更换回调地址会很麻烦,只是建议,可根据自己的实际情况进行选择.
1. 前往 [GitHub Developer Settings](https://github.com/settings/developers)
2. 点击 **New OAuth App**
3. 填写：

| 字段 | 本地开发值 | Vercel 部署值 | 自建服务器值 |
|------|-----------|--------------|-------------|
| Application name | `Yuamli (dev)` | `Yuamli` | `Yuamli` |
| Homepage URL | `http://localhost:3000` | `https://xxx.vercel.app` | `https://your-domain.com` |
| Authorization callback URL | `http://localhost:3000/api/auth/github/callback` | `https://xxx.vercel.app/api/auth/github/callback` | `https://your-domain.com/api/auth/github/callback` |

4. 点击 **Register application**
5. 记录 **Client ID**（公开）和 **Client Secret**（保密，点击 "Generate a new client secret" 获取）

- **变量说明**

| 变量名 | 必填 | 说明 |
|--------|------|------|
| `NEXT_PUBLIC_GITHUB_CLIENT_ID` | 是 | GitHub OAuth App 的 Client ID（前端公开） |
| `GITHUB_CLIENT_ID` | 是 | 同上（后端使用） |
| `GITHUB_CLIENT_SECRET` | 是 | GitHub OAuth App 的 Client Secret（**保密且只能复制一次,建议截图保存,否则就要重新申请**） |
---


## GitHub 仓库上传指南
>[!note]
>本地开发测试完成后，需要将项目代码上传到 个人的GitHub 仓库。此时会产生部分不需要的文件，需要进行筛选后上传。

### 需要上传的文件 ✅

| 文件/目录 | 说明 |
|-----------|------|
| `src/` | 所有源代码（含 UI 组件） |
| `data/` | JSON 数据文件（初始数据） |
| `public/` | 静态资源（logo、robots.txt） |
| `.env.example` | 环境变量模板（**不含密钥**） |
| `.gitignore` | Git 忽略规则 |
| `package.json` | 项目依赖声明 |
| `next.config.ts` | Next.js 框架配置 |
| `tsconfig.json` | TypeScript 配置 |
| `tailwind.config.ts` | Tailwind CSS 配置 |
| `postcss.config.mjs` | PostCSS 配置 |
| `components.json` | shadcn/ui 配置 |
| `Caddyfile` | 反向代理配置（可选） |

### 不要上传的文件 ❌


| 文件/目录 | 原因 |
|-----------|------|
| `.env` | **包含数据库路径等本地配置** |
| `.env.local` | **包含 GitHub OAuth 密钥等敏感信息**,<br>多为本地开发测试配置环境 |
| `node_modules/` | 依赖包,`pnpm install` 会自动生成 |
| `.next/` | 构建缓存，每次 build 自动生成 |
| `bun.lock` / `pnpm-lock.yaml` | 只保留你使用的包管理器的锁文件 |
| `prisma/` | 未使用的 Prisma 配置 |
| `upload/` | 临时上传目录 |
| `scripts/` | 开发脚本（如有） |

### 上传步骤

```bash
# 1. 在项目根目录初始化 Git（如果还没有）
git init

# 2. 添加所有文件（.gitignore 会自动排除不需要的）
git add .

# 3. 查看将要提交的文件（确认没有 .env / node_modules）
git status

# 4. 提交
git commit -m "Yuamli V-1.0.0 初始版本"

# 5. 关联 GitHub 远程仓库（替换为你的仓库地址）
git remote add origin https://github.com/你的用户名/你的仓库名.git

# 6. 推送
git branch -M main
git push -u origin main
```

---

### 在 Vercel 导入项目

1. 登录 [Vercel Dashboard](https://vercel.com/dashboard)
2. 点击 **Add New Project**
3. 关联你的 GitHub 仓库并导入
4. Framework Preset 会自动识别为 **Next.js**，无需修改

### 配置环境变量

进入项目 → **Settings** → **Environment Variables**，添加以下三个变量（如果使用 GitHub 登录）：

| 变量名 | 值 | 环境 |
|--------|-----|------|
| `NEXT_PUBLIC_GITHUB_CLIENT_ID` | 你的 GitHub Client ID | Production / Preview / Development 全选 |
| `GITHUB_CLIENT_ID` | 同上 | 同上 |
| `GITHUB_CLIENT_SECRET` | 你的 GitHub Client Secret | 同上 |

> KV 相关的 `KV_REST_API_URL` 和 `KV_REST_API_TOKEN` **不需要手动填写**，创建 KV 实例后 Vercel 会自动注入。

### 创建 Vercel KV 存储

1. 在 Vercel 项目页面，点击顶部导航栏的 **Storage** 标签
2. 点击 **Create Database**
3. 选择 **KV (Redis)**
4. 选择区域（推荐 `Singapore` 或 `Hong Kong`，延迟最低）
5. 点击 **Create**

创建完成后，Vercel 会自动将以下环境变量注入到项目中，无需手动操作：

- `KV_REST_API_URL` — Redis 连接地址
- `KV_REST_API_TOKEN` — 认证 Token
- `KV_REST_API_READ_ONLY_TOKEN` — 只读 Token（项目未使用）

> **验证方法**：进入 **Settings → Environment Variables**，确认能看到以上三个变量。
- **存储机制说明**

Yuamli 的数据存储会根据运行环境**自动切换**，无需手动配置：

| 环境 | 存储方式 | 触发条件 |
|------|----------|----------|
| 本地开发 | `data/` 目录下的 JSON 文件 | 未检测到 `KV_REST_API_URL` 环境变量 |
| Vercel 部署 | Vercel KV（Redis） | 检测到 `KV_REST_API_URL` 环境变量 |

系统共存储三类数据：

| KV Key / 文件名 | 内容 | 说明 |
|-----------------|------|------|
| `comments` | `comments.json` | 所有留言（含嵌套回复关系） |
| `users` | `users.json` | 所有注册用户（游客 + GitHub） |
| `config` | `config.json` | 站点配置（管理员密码、邮箱通知等） |

> **为什么 Vercel 需要用 KV？** Vercel 的文件系统是只读的，无法写入 JSON 文件。Vercel KV 底层是 Upstash Redis，通过 REST API 通信，本项目已内置适配器，无需安装额外 SDK。

### 更新 GitHub OAuth 回调地址

回到 [GitHub Developer Settings](https://github.com/settings/developers)，将 OAuth App 的 **Authorization callback URL** 修改为：

```
https://你的项目名.vercel.app/api/auth/github/callback
```

如果绑定了自定义域名，则使用自定义域名。

### 重新部署

回到 Vercel，在 **Deployments** 页面点击最新部署右侧的 `···` → **Redeploy**，确保新环境变量生效。

---

## 部署到自建服务器

自建服务器使用 JSON 文件存储，无需配置 KV。

### 方式一：直接运行

```bash
npm install
npm run build
npm start
```

默认监听 3000 端口。

### 方式二：Caddy 反向代理

项目根目录已附带 `Caddyfile`，修改其中的端口号后直接使用：

```bash
caddy run
```

### 方式三：Nginx 反向代理

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 方式三：PM2 守护进程

```bash
npm install -g pm2
pm2 start npm --name "yuamli" -- start
pm2 save
pm2 startup
```

---

## GitHub OAuth 配置详解

### 创建 OAuth App



### 环境变量对应关系

OAuth App 创建后，将两个值分别填入三个环境变量：

```env
# 前端跳转 GitHub 授权页时使用（暴露在浏览器中，是公开的）
NEXT_PUBLIC_GITHUB_CLIENT_ID=Ov23liAbCdEfGh

# 后端用 code 换 token 时使用（保密）
GITHUB_CLIENT_ID=Ov23liAbCdEfGh
GITHUB_CLIENT_SECRET=1a2b3c4d5e6f7g8h9i0j
```

`GITHUB_CLIENT_ID` 和 `NEXT_PUBLIC_GITHUB_CLIENT_ID` 填同一个值，前者给后端用，后者给前端用。

### 更换部署环境时的注意事项

每次更换部署地址（本地 → Vercel → 自定义域名），都需要**同步更新**：
1. GitHub OAuth App 的 **Homepage URL** 和 **Authorization callback URL**
2. `.env.local` 中的 `NEXT_PUBLIC_GITHUB_CLIENT_ID`（如果 Client ID 没变则不需要）

---

## 后台管理

### 访问后台

1. 访问 `https://你的域名/admin`
2. 输入管理密码（默认 `20030723`）
3. 点击「登录」

### 后台功能

- **留言管理**：查看全部留言、删除、置顶、设为精华、批量操作
- **用户列表**：查看注册用户信息
- **设置**：修改密码、通知邮箱、通知模板
- **数据**：导出/导入 JSON 备份

### 修改管理密码

1. 登录后台
2. 切换到「设置」标签页
3. 在「修改密码」区域填写：
   - 原密码
   - 新密码（至少 4 个字符）
   - 确认新密码
4. 点击「保存」→ 密码立即生效，下次登录需使用新密码

---

## 修改导航栏 (nav/版本号)

导航栏定义在 `src/app/page.tsx` 的 `<header>` 区域。

### 修改标题/Logo

```tsx
// src/app/page.tsx 中的 header 部分
<header className="border-b bg-white/60 backdrop-blur-sm sticky top-0 z-50">
  <div className="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
    <div className="flex items-center gap-2">
      <MessageCircleHeart className="h-5 w-5 text-emerald-600" />
      <h1 className="text-lg font-bold">Yuamli</h1>  {/* ← 修改这里 */}
      <Badge variant="secondary" className="text-[10px] h-4 font-normal">v1.0.0</Badge>  {/* ← 版本号 */}
    </div>
    ...
  </div>
</header>
```

## 修改页脚 (footer/版本号)

页脚定义在 `src/app/page.tsx` 的 `<footer>` 区域。

### 修改页脚内容

```tsx
// src/app/page.tsx 中的 footer 部分
<footer className="border-t bg-white/60 backdrop-blur-sm">
  <div className="max-w-2xl mx-auto px-4 py-4 text-center">
    <p className="text-xs text-muted-foreground">
      Powered by <span className="font-medium text-foreground">Yuamli</span> v1.0.0
      {/* ↑ 修改 "Yuamli" 和版本号 */}
    </p>
    {/* 可以添加更多内容 */}
    <p className="text-xs text-muted-foreground mt-1">
      © 2024 你的名字 · <a href="https://你的域名" className="hover:text-foreground">主页</a>
    </p>
  </div>
</footer>
```

### 后台页面的页脚

后台页脚在 `src/app/admin/page.tsx` 中：

```tsx
<footer className="border-t bg-white/60 backdrop-blur-sm">
  <div className="max-w-3xl mx-auto px-4 py-4 text-center">
    <p className="text-xs text-stone-400">
      Powered by <span className="font-medium text-stone-600">Yuamli</span> v1.0.0
      {/* ↑ 修改这里 */}
    </p>
  </div>
</footer>
```

---


### 4. layout.tsx 元数据

**文件**: `src/app/layout.tsx`

```tsx
export const metadata: Metadata = {
  title: "Yuamli - 轻量留言系统",
  description: "Yuamli V-1.0.0 轻量级留言系统...",  // ← 修改版本号
  // ...
};
```

### 5. package.json

**文件**: `package.json`

```json
{
  "version": "0.2.0"  // ← 修改版本号
}
```

---

### 数据备份与恢复

1. **自动检测**

- Vercel KV 免费方案使用 **RAM-only** 存储，不具备持久化能力。当 Redis 实例发生重启或迁移时，数据可能丢失。系统在管理后台提供了手动备份功能。

2. **导出格式**

- 导出的 JSON 文件结构如下：

```json
{
  "_meta": {
    "exportedAt": "2026-06-25T13:30:00.000Z",
    "version": "1.0.1",
    "source": "Yuamli"
  },
  "comments": [ ... ],
  "users": [ ... ],
  "config": { ... }
}
```

3. **导入流程**

- 点击管理后台的 **导入数据** 按钮
- 选择之前导出的 `.json` 文件
- 选择导入模式：
   - 弹出第一个对话框时点 **确定** = 覆盖模式（替换全部数据）
   - 点 **取消** = 合并模式（只添加新记录）
4. 确认操作后等待导入完成

5. **导入安全**

- 导入时会验证文件格式，非 Yuamli 备份文件会被拒绝
- 覆盖模式有二次确认提示，防止误操作
- 导入完成后页面数据自动刷新

---

## API 接口文档

### 认证相关

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/api/auth/register` | 游客注册（QQ 号必填，邮箱可选） |
| `POST` | `/api/auth/login` | 游客登录（支持 `remember` 字段实现 30 天免登录） |
| `GET` | `/api/auth/session` | 获取当前会话用户信息 |
| `POST` | `/api/auth/session` | 退出登录 |
| `GET` | `/api/auth/github/callback` | GitHub OAuth 回调（服务端处理，设置 Cookie 后重定向） |
| `POST` | `/api/auth/github` | GitHub Token 交换（备用，JSON 接口模式） |

### 留言相关

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `/api/comments` | 获取留言树（递归嵌套结构） |
| `POST` | `/api/comments` | 发表留言或回复（需登录） |
| `PUT` | `/api/comments/[id]` | 编辑留言内容 |
| `DELETE` | `/api/comments/[id]` | 删除留言及所有子回复 |

### 管理相关

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/api/admin` | 管理员登录 |
| `GET` | `/api/admin` | 获取用户列表 + 站点配置 |
| `DELETE` | `/api/admin` | 退出管理 |
| `POST` | `/api/admin/notify` | 保存通知设置 |
| `GET` | `/api/admin/comments` | 获取所有留言（管理视图，按时间倒序） |
| `POST` | `/api/admin/comments` | 批量操作（`batch_delete` / `batch_pin` / `batch_unpin` / `batch_feature` / `batch_unfeature`） |
| `GET` | `/api/admin/data` | 导出全部数据为 JSON 文件下载 |
| `POST` | `/api/admin/data` | 导入数据（`mode: "overwrite"` 或 `mode: "merge"`） |

---

## 常见问题

### Q: 部署到 Vercel 后游客注册 / 登录不生效？

**检查 Vercel KV 是否正确配置。** Vercel 的文件系统是只读的，所有数据写入必须通过 KV。进入 Vercel 项目的 **Storage** 标签，确认已创建 KV 实例且关联到当前项目。然后在 **Settings → Environment Variables** 中确认 `KV_REST_API_URL` 和 `KV_REST_API_TOKEN` 存在。

### Q: GitHub 登录后跳转回来仍然显示未登录？

1. 确认 `.env.local` 和 Vercel 环境变量中**同时**配置了 `NEXT_PUBLIC_GITHUB_CLIENT_ID`、`GITHUB_CLIENT_ID`、`GITHUB_CLIENT_SECRET` 三个变量
2. 确认 GitHub OAuth App 的 **Authorization callback URL** 与实际部署地址完全一致（包括 `https` 和末尾路径）
3. Vercel 部署后记得**重新部署**使新环境变量生效

### Q: 构建时报 `Module not found: Can't resolve '@vercel/kv'`？

V-1.0.1 已移除 `@vercel/kv` 依赖，改为使用原生 `fetch` 调用 Redis REST API。如果你从旧版本升级，请确认 `package.json` 中已删除 `"@vercel/kv"` 依赖行。

### Q: Vercel KV 免费方案够用吗？

免费方案提供 30 MB 内存存储、100 ops/s 吞吐量。对于个人留言系统完全足够。唯一限制是 **RAM-only 无持久化**，建议定期使用管理后台的导出功能备份数据。


### Q: 可以部署到 Cloudflare Pages 等其他平台吗？

可以，但需要注意：Cloudflare Pages 的构建产物是只读的，和 Vercel 一样需要外部存储。你需要自行对接 Cloudflare KV 或 D1 数据库，并修改 `src/lib/adapter.ts` 中的存储逻辑。

---

## 更新日志

### V-1.0.0 (2026-06-23)

- 初始版本发布
- QQ 号注册登录（主）、邮箱注册（辅）
- GitHub OAuth 第三方登录
- 无限制嵌套回复
- Markdown 语法支持 + 实时预览
- 后台管理：用户管理、留言批量管理（删除 / 置顶 / 精华）
- 邮箱通知设置 + 自定义邮件模板
- "记住我"登录（30 天免登录）
- 响应式布局 + 深色模式

### V-1.0.1 (2026-06-25)

- **修复**：游客注册 / 登录在 Vercel 部署后 Cookie 未设置的问题（Next.js 15+ Route Handler 中 `cookies()` 为只读）
- **修复**：GitHub OAuth 回调后登录状态不生效的问题（增加前端会话获取重试机制）
- **修复**：管理员认证 Cookie 设置方式兼容 Next.js 16
- **移除**：`@vercel/kv` 依赖，改为原生 `fetch` 调用 Redis REST API，消除废弃包导致的构建失败
- **新增**：数据备份功能 — 管理后台支持一键导出 / 导入全部数据（覆盖或合并模式）
- **优化**：GitHub 回调增加重试机制，应对 CDN 边缘情况下的 Cookie 时序问题

### V-1.0.2 (2026-06-27)
- **修改**：改前台数据管理为后台数据管理
- **增加**：添加`/admin`页后台管理系统,管理密码可一键修改

