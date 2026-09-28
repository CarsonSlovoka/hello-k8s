# 在 GitHub Pages 閱讀

本機仍用 `mdbook serve` 或 `make mdbook.serve`
推到 GitHub 之後，可以用 GitHub Pages 在瀏覽器看同一份筆記

## 會用到的檔案

| 檔案 | 作用 |
|---|---|
| `.github/workflows/mdbook.yml` | 在 `main` / `master` 推送時建置 `docs/`，部署到 Pages |
| `book.toml` 的 `site-url` | 告訴 mdBook 網站不在網域根目錄，避免 404 頁的 CSS／連結壞掉 |

建置產物在 `book/`，已列入 `.gitignore`，不要把編譯結果提交進 git

## 你需要在 GitHub 做的設定

1. 把這個專案建成 GitHub 倉庫並推送（預設分支用 `main` 或 `master` 都可以，workflow 兩個都聽）
2. 打開倉庫 **Settings → Pages**
3. **Build and deployment → Source** 選 **GitHub Actions**（不要選「Deploy from a branch」）
4. 確認 **Settings → Actions → General** 允許這個倉庫跑 Actions。若組織有限制，需要允許 `GITHUB_TOKEN` 部署 Pages

第一次成功部署後，網址通常是：

```text
https://<你的帳號>.github.io/<倉庫名稱>/
```

若倉庫就叫 `hello-k8s`，會是 `https://<你的帳號>.github.io/hello-k8s/`
Actions 的 Deploy job 結束後，也可以在 workflow 摘要裡看到 `page_url`

## 本機與 CI 的差異

- 本機：`mdbook build` / `mdbook serve` 讀 `book.toml`，`site-url` 預設 `/hello-k8s/`
- CI：用環境變數 `MDBOOK_OUTPUT__HTML__SITE_URL=/<實際倉庫名>/` 覆寫，避免你把倉庫改名後路徑錯掉

例外：若你用的是使用者／組織站（倉庫名是 `<帳號>.github.io`），網站在網域根目錄。那時要把 workflow 裡的 `MDBOOK_OUTPUT__HTML__SITE_URL` 改成 `/`，也把 `book.toml` 的 `site-url` 改成 `/`

## 常見故障

- **Settings → Pages 仍選 branch**
  workflow 會跑完，但網站不是由這份 Actions 發布。改成 GitHub Actions

- **Pages 建成功但 CSS 沒有、或開子頁面 404**
  `site-url` 與倉庫名稱不一致。看 workflow 的 `MDBOOK_OUTPUT__HTML__SITE_URL` 是否為 `/<repo>/`

- **Action 失敗：pages 權限不足**
  workflow 已宣告 `pages: write` 與 `id-token: write`。若仍失敗，檢查組織是否禁止 GitHub Pages，或環境 `github-pages` 是否在等你按 Approve

- **只改了 `docs/` 卻沒更新網站**
  確認變更已推到 `main` 或 `master`，並打開 Actions 看 `Deploy mdBook to GitHub Pages` 是否成功。也可在 Actions 分頁手動跑 `workflow_dispatch`
