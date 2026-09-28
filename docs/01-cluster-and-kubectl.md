# 第一課：重建叢集並確認 kubectl

預估時間：30–45 分鐘（第一次拉 node image 會更久）。

## 學習目標

- 分清 `container k8s` 與 `kubectl` 各管什麼
- 重新建立 `hello-cluster`
- 確認 `kubectl` current context 指向這座叢集
- 會讀 Node 與系統 Pod 是否 Ready

## 必要概念

- **Cluster**：整套控制平面 + 節點。練習對象叫 `hello-cluster`。
- **Node**：實際跑 Pod 的機器。這套本機叢集是單節點。
- **Pod**：Kubernetes 排程的最小單位。系統元件也以 Pod 形式跑在 `kube-system`。
- **Namespace**：資源的分組。不加 `-A` 時，`kubectl get pods` 只看預設的 `default`（剛建好的叢集通常是空的）。
- **kubeconfig / context**：`kubectl` 連哪一座叢集的設定。current context 錯，後面所有指令都會打到別的地方。

對照：`container ls -a` 看到的是「叢集節點那顆 VM／容器」；`kubectl get pods -A` 看到的是「那顆節點裡面被 Kubernetes 排程出來的 Pod」。

## 建立前先確認

```bash
container --version
container k8s --help
container system start
container k8s list
container ls -a
```

`container system start` 會啟動 Apple container 後台。沒有它就無法建立叢集 VM。
若 `hello-cluster` 已存在且狀態是 `running`，不要重複 `create`。

## 建立叢集

專案 Makefile 使用 3GB 記憶體，與本機實測一致：

```bash
container k8s create -m 3G --name hello-cluster
```

這條指令會：

1. 拉 node image（本機實際跑起來是 Kubernetes **v1.35.5**）
2. 啟動一顆 Linux VM
3. 在裡面做 `kubeadm init`
4. 安裝 CNI（本機是 **kindnet**）
5. 把憑證寫進 `~/.kube/config`

會改動的東西：本機多一個叢集 VM、kubeconfig 多一個 `hello-cluster` context、佔用約 3 CPU / 3072 MB。

確認：

```bash
container k8s list
container ls -a
```

## 確認 kubectl 連對叢集

改任何資源前都先看 context：

```bash
kubectl config get-contexts
kubectl config current-context
```

若不是 `hello-cluster`：

```bash
kubectl config use-context hello-cluster
```

若完全沒有這個 context：

```bash
container k8s write-config --name hello-cluster
kubectl config get-contexts
```

接著確認 API 與 Node：

```bash
kubectl cluster-info
kubectl get nodes
kubectl get nodes -o wide
```

`-o wide` 會多出 Internal IP、OS、kernel、container runtime。

看系統 Pod：

```bash
kubectl get pods -A
```

第一次讀 Node 細節：

```bash
kubectl describe node hello-cluster
```

先掃：

- `Conditions`：`Ready` 應為 `True`
- `Addresses`
- `Taints`：單節點練習叢集通常已拿掉 `NoSchedule`，否則一般應用 Pod 排不上去
- `Events`：開機、CNI、kubelet 發生過什麼

## 本機實際觀察（2026-09-28）

`container k8s list`：

- Node 名稱：`hello-cluster`
- 角色：`control-plane,worker`（單節點同時當控制平面與可排程工作節點）
- 狀態：`running`
- 資源：3 CPUs、3072 MB
- 連接：主機 `6445 ->` 節點 `6443`

`kubectl`：

- current context：`hello-cluster`（唯一 context，且已選中）
- API：`https://127.0.0.1:6445`
- Node `STATUS=Ready`，`ROLES=control-plane`，版本 `v1.35.5`
- `CONTAINER-RUNTIME=containerd://2.3.1`
- Node `INTERNAL-IP` 為 `192.168.64.2`；`container k8s list` 的 `ADDR` 為 `192.168.64.2`


系統 Pod（皆 `1/1 Running`，RESTARTS=0）：

| 名稱 | 作用（先記這個層級即可） |
|---|---|
| `kube-apiserver-hello-cluster` | 叢集 API，`kubectl` 就是打這裡 |
| `kube-controller-manager-hello-cluster` | 讓實際狀態追趕你宣告的狀態 |
| `kube-scheduler-hello-cluster` | 決定 Pod 排到哪顆 Node |
| `etcd-hello-cluster` | 叢集資料 |
| `coredns-...`（兩個） | 叢集內 DNS |
| `kindnet-...` | Pod 網路（CNI） |
| `kube-proxy-...` | Service 轉發相關 |

`default` namespace 目前沒有應用 Pod，這是預期結果。

## 動手練習

### 練習 A：分辨容器與 Pod

並排執行：

```bash
container ls -a
kubectl get pods -A
```

左邊是叢集節點 VM；右邊 `kube-system` 裡才是 Kubernetes 排程出來的系統 Pod。

### 練習 B：讀懂 `kubectl get nodes` 欄位

```bash
kubectl get nodes
kubectl get nodes -o wide
```

對照本機輸出：

- `STATUS=Ready`：kubelet 回報節點可排程
- `ROLES=control-plane`：這是控制平面節點。`container k8s list` 額外標了 `worker`，代表這顆單節點也被拿來跑工作負載
- `INTERNAL-IP`：節點在叢集網路裡的位址，不是你在瀏覽器打的 `127.0.0.1`

## 常見故障

1. **`create` 失敗或很久**
   先確認 `container system start`。第一次拉 `kindest/node` 需要網路。

2. **connection refused / timeout**
   看 `container k8s list` 是否還 `running`，以及 current context 是否為 `hello-cluster`。叢集在跑但連不上時，再試 `container k8s write-config --name hello-cluster`。

3. **current context 指到別的叢集**
   `kubectl config use-context hello-cluster`。未加 `--context` 的指令都會打到 current context。

4. **Node 一直 NotReady**
   ```bash
   kubectl describe node hello-cluster
   kubectl get pods -A
   kubectl get events -A --sort-by='.lastTimestamp'
   ```
   先讀 `Conditions`、異常 Pod、最近 Events，不要直接刪叢集重裝。

## 清理（這課先不要做）

叢集要留著給下一課部署應用。現在不要 `container k8s delete` / `rm`，也不要 `container system stop`。

若確定整課重來，只刪這個練習叢集：

```bash
kubectl config current-context
container k8s delete --name hello-cluster
```

`delete` 與 `rm` 相同。不要省略 `--name`。

Makefile 的 `make stop` 會刪叢集**並且** `container system stop`，範圍比「只刪練習叢集」更大，這課不要用。

## 理解問題（對照）

1. **為什麼 `container ls -a` 有東西，不代表 `kubectl get pods` 看得到應用？**
   前者看的是節點 VM 在不在。後者看的是 Kubernetes 裡有沒有 Pod。叢集活著時，通常只看得到 `kube-system` 的系統 Pod；應用要另外部署。

2. **`kubectl` 怎麼知道要連 `hello-cluster`？**
   讀 `~/.kube/config` 的 current context。本機該 context 的 API 是 `https://127.0.0.1:6445`。

3. **current context 指錯叢集時，`kubectl get nodes` 會怎樣？**
   它不會幫你改回 `hello-cluster`，而是查「目前選中的那一座」。查到的 Node 列表可能完全是另一套環境，也因此之後的 `apply` / `delete` 可能打到錯的地方。
