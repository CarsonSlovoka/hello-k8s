# scripts/init.sh
# 不經過 Makefile 的上手手冊：讓第一次接觸的人先看過完整流程
# 日常練習請用倉庫根目錄的 Makefile（建立叢集時會指定 -m 3G）
#
# 這份檔案可以當參考逐行複製，不建議直接 bash scripts/init.sh：
# 跑完全檔會在最後刪掉 hello-cluster 並停止 container system

brew install kubectl kind container

# 啟動服務
container system start

# 創建
container k8s create --name hello-cluster

# 查詢
container k8s ls
container ls -a

# 終止
container k8s rm     --name hello-cluster
container system stop

