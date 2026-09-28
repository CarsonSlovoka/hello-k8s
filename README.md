# hello-k8s

從 0 學習 Kubernetes 的實作筆記與練習專案。

- 本機叢集：Apple `container k8s`，練習叢集名稱 `hello-cluster`
- 操作介面：`kubectl`
- 課程筆記：`docs/`，用 [mdBook](https://rust-lang.github.io/mdBook/) 閱讀

```bash
# 預覽筆記（需已安裝 mdbook）
mdbook serve
# 或
make mdbook.serve
```

推到 GitHub 並在 **Settings → Pages → Source** 選 **GitHub Actions** 後，可用 GitHub Pages 閱讀。  
詳細步驟見 [docs/github-pages.md](docs/github-pages.md)。

目前進度：已能建立叢集，並確認 `kubectl` 連到正確的 Node 與系統 Pod。尚未部署應用。
