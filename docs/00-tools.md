# 工具分工：container、kubectl、kind

本機同時裝了三個容易混淆的工具。前期只使用前兩個。

| 工具 | 負責什麼 | 這階段怎麼用 |
|---|---|---|
| Apple `container` / `container k8s` | 在 Mac 上跑 Linux 輕量 VM，並建立／列出／啟動／刪除本機 Kubernetes 叢集 | 管叢集生命週期，以及之後把本機映像載入叢集（`load-image`） |
| `kubectl` | 對「已經在跑的 Kubernetes API」查詢或改資源 | 確認 context、看 Node／Pod、之後才 `apply` / `delete` |
| 獨立的 `kind` | 另一套本機叢集工具 | **現在不用。** 不要對 `hello-cluster` 下 `kind create cluster` 或 `kind load docker-image` |

## 為什麼看起來很像 kind

`container k8s create` 內部會用 `kindest/node` 這類 node image，並用 `kubeadm` 初始化。
這只表示「節點映像與啟動方式類似 kind」，**不表示**你現在的叢集是用 `kind` CLI 建立的。

載入映像時要用：

```bash
container k8s load-image --name hello-cluster <image>
```

而不是 `kind load docker-image`。本機也不假設有 Docker daemon。

## 本機實際的 `container k8s` 子指令

來自 `container k8s --help`（EXPERIMENTAL）：

- `create`：建立並啟動叢集
- `delete` / `rm`：刪除叢集
- `list` / `ls`：列出叢集與節點
- `load-image`：把映像載入叢集的 containerd
- `start`：啟動已停止的叢集
- `write-config`：把 context 寫進 kubeconfig

`list`/`ls`、`delete`/`rm` 是同一組指令的別名，兩種寫法都可以。

## kubeconfig 與 context

叢集建立後，憑證會寫進 `~/.kube/config`。
`kubectl` 靠 **current context** 決定連哪一座叢集。

```bash
kubectl config get-contexts
kubectl config current-context
kubectl config use-context hello-cluster
```

`container k8s write-config --name hello-cluster` 用來補寫或重寫 kubeconfig，不會取代你每次操作前的確認步驟。
