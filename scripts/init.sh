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

