SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.PHONY: all help version check_dep run start create stop \
	mdbook.init mdbook.serve \
	config config.context \
	kubectl.cluster kubectl.get

REQUIRED_PACKAGES = kubectl kind container \
	mdbook
CLUSTER_NAME = hello-cluster


# ---------------------------------------------------------------------------
# 顏色：非 TTY 或設了 NO_COLOR 時自動關掉
# ---------------------------------------------------------------------------
NO_COLOR ?=
ifeq ($(NO_COLOR),)
  C_RESET   := $(shell printf '\033[0m')
  C_BOLD    := $(shell printf '\033[1m')
  C_DIM     := $(shell printf '\033[2m')
  C_RED     := $(shell printf '\033[31m')
  C_GREEN   := $(shell printf '\033[32m')
  C_YELLOW  := $(shell printf '\033[33m')
  C_BLUE    := $(shell printf '\033[34m')
  C_MAGENTA := $(shell printf '\033[35m')
  C_CYAN    := $(shell printf '\033[36m')

  C_HEADER  := $(shell printf '\033[48;2;0;0;255m\033[38;2;255;255;255m')
else
  C_RESET :=
  C_BOLD :=
  C_DIM :=
  C_RED :=
  C_GREEN :=
  C_YELLOW :=
  C_BLUE :=
  C_MAGENTA :=
  C_CYAN :=
  C_HEADER :=
endif

# 狀態訊息
define header
	printf '$(C_BOLD)$(C_HEADER)━━ %s$(C_RESET)\n' "$(1)"
endef

define info
	printf '$(C_CYAN)ℹ  %s$(C_RESET)\n' "$(1)"
endef

define ok
	printf '$(C_GREEN)✔  %s$(C_RESET)\n' "$(1)"
endef

define warn
	printf '$(C_YELLOW)⚠  %s$(C_RESET)\n' "$(1)"
endef

# 先印出「即將執行的指令」（青色），再真正執行
define run
	printf '$(C_BOLD)$(C_BLUE)→$(C_RESET) $(C_MAGENTA)%s$(C_RESET)\n' "$(1)"
	$(1)
endef

help:
	@$(call header,Targets)
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "version"           "查看 container 版本"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "run"               "start + create 後列出叢集"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "start"             "啟動 container system"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "create"            "建立 $(CLUSTER_NAME)"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "stop"              "刪除叢集並停止 system"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "config"            "顯示 ~/.kube/config"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "config.context"    "從 ~/.kube/config 得到相關的context"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "kubectl.cluster"   "cluster-info 確認打到這座叢集的 API Server"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "kubectl.get"       "kubectl get <name>: Display one or many resources."

mdbook.init:
	@$(call header,生成book.toml)
	@$(call run,   mdbook init hello-k8s)
	@$(call run,   mv -v  hello-k8s/* .)
	@$(call run,   rm -rf hello-k8s)

mdbook.build.stamp: book.toml $(fd . -e md docs)
	@$(call run,   mdbook build)
	touch mdbook.build.stamp

mdbook.serve: book.toml mdbook.build.stamp
	@$(call run,   mdbook serve)

check_dep.stamp:
	@$(call header,檢查相依套件)
	for pkg in $(REQUIRED_PACKAGES); do \
		printf '$(C_CYAN)檢查:$(C_RESET) %s\n' "$$pkg"; \
		if ! brew list "$$pkg" >/dev/null 2>&1; then \
			printf '$(C_YELLOW)⚠  未安裝 %s，正在自動安裝...$(C_RESET)\n' "$$pkg"; \
			brew install "$$pkg" || exit 1; \
			printf '$(C_GREEN)✔  已安裝 %s$(C_RESET)\n' "$$pkg"; \
		else \
			printf '$(C_GREEN)✔  %s 已安裝$(C_RESET)\n' "$$pkg"; \
		fi; \
	done
	touch check_dep.stamp

check_dep: check_dep.stamp

version: check_dep.stamp
	@$(call header,container 版本資訊)
	@$(call run,container --version)
	container --version > k8s.txt
	@$(call run,container k8s --help)
	container k8s --help >> k8s.txt
	@$(call ok,已寫入 k8s.txt)

start:
	@$(call header,啟動 container system)
	@$(call run,container system start)

create:
	@$(call header,建立叢集 cluster)
	@# 作用： 拉 node image (預設常見為 kindest/node)、啟動一顆 Linux VM、在裡面做 kubeadm init、裝 CNI（常見是 kindnet）、把憑證寫進 ~/.kube/config
	@$(call run,container k8s create -m 3G --name $(CLUSTER_NAME))
	@# 會改動什麼：
	@# 本機多一個名為 $(CLUSTER_NAME) 的叢集容器／VM
	@# ~/.kube/config 多一個同名（或極相近）的 context
	@# 你的 Mac 會佔用 CPU／記憶體（預設大約主機的 1/4，至少約 2 CPU / 2GB） 使用 -m 可以指定給多少記憶體

run: start create
	@$(call header,目前狀態)
	@$(call run,container k8s ls)
	@$(call run,container ls -a)

# stop 之後 ~/.kube/config 的內容也會清除
stop: check_dep.stamp
	@$(call header,停止並清理)
	@$(call run,container k8s rm --name $(CLUSTER_NAME))
	@$(call run,container system stop)
	@$(call ok,已停止)

config:
	@$(call header, ~/.kube/config)
	@printf '$(C_DIM)'
	cat ~/.kube/config
	@printf '$(C_RESET)'


# Tip: 其實這些context的內容，都可以在 ~/.kube/config 中看到
config.context:
	@$(call header,context)

	@# 列出本機所有已知叢集。* 那一列是目前目標
	@$(call run,kubectl config get-contexts)

	@# use-context 可以切換成指定的cluster
	@# 這會改你之後所有未加 --context 的 kubectl 指令
	@$(call run,kubectl config use-context $(CLUSTER_NAME))

	@# 僅顯示名稱
	@$(call run,kubectl config current-context)

kubectl.cluster:
	@$(call header,確認打到這座叢集的 API Server)
	@$(call run,   kubectl cluster-info)

kubectl.get:
	@$(call header,kubectl get nodes 相關)
	@$(call run,   kubectl get nodes)

	@# -o wide有額外的資訊:{INTERNAL-IP, EXTERNAL-IP, OS-IMAGE, KERNEL-VERSION, CONTAINER-RUNTIME}
	@$(call run,   kubectl get nodes -o wide)


	@$(call header,kubectl get pods 相關)
	@$(call run,   kubectl get pods -A)
	@# -A / --all-namespaces：看所有 namespace，不只預設的 default
	@# NAMESPACE     NAME                                    READY   STATUS    RESTARTS   AGE
	@# kube-system   coredns-7d764666f9-8chw5                1/1     Running   0          87m
	@# kube-system   coredns-7d764666f9-wzlz9                1/1     Running   0          87m
	@# kube-system   etcd-hello-cluster                      1/1     Running   0          88m
	@# kube-system   kindnet-bsnzq                           1/1     Running   0          87m
	@# kube-system   kube-apiserver-hello-cluster            1/1     Running   0          88m
	@# kube-system   kube-controller-manager-hello-cluster   1/1     Running   0          88m
	@# kube-system   kube-proxy-w5kdl                        1/1     Running   0          87m
	@# kube-system   kube-scheduler-hello-cluster            1/1     Running   0          88m

	@# coredns（叢集內 DNS）
	@# kindnet 或類似 CNI
	@# 控制平面: kube-apiserver、kube-controller-manager、kube-scheduler、etcd
	@# kube-proxy
