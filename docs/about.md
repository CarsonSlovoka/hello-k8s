# 關於這份筆記

這是跟著本機實作寫下來的 Kubernetes 學習紀錄，不是完整官方文件的翻譯。

## 環境

- 電腦：Mac mini M4 Pro，macOS，終端機
- 已安裝：`kubectl`、`kind`、Apple `container`（Homebrew）、`mdbook`
- 練習叢集名稱：`hello-cluster`
- 前期建立叢集的方式：Apple `container k8s`，**不是**獨立的 `kind create cluster`

線上閱讀：把倉庫推上 GitHub，並依 [在 GitHub Pages 閱讀](./github-pages.md) 開啟 Pages。

## 怎麼用

1. 先在終端機自己打指令，對照預期結果。
2. 出錯時先看 `kubectl get`、`describe`、events，再查對應課文的「常見故障」。
3. 改動叢集資源前，先確認：

```bash
kubectl config current-context
```

必須是 `hello-cluster`。

## 目前進度

已完成：啟動 container 系統、建立／列出／刪除本機叢集，並重新建立 `hello-cluster` 後確認：

- current context = `hello-cluster`
- Node `Ready`
- `kube-system` 系統 Pod 皆 `Running`

未完成：部署應用、Service、自行建置映像檔、Go 服務作品集。

## 筆記原則

- 一次只寫當前單元，不提前展開後面所有課。
- 指令以本機 `container k8s --help` 與實際輸出為準。
- `container k8s` 標示為 **EXPERIMENTAL**，子指令名稱可能隨版本調整。
