SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.PHONY: all help info check_dep run start create stop config

REQUIRED_PACKAGES = kubectl kind container

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
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "info"   "查看 container 版本"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "run"    "start + create 後列出叢集"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "start"  "啟動 container system"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "create" "建立 hello-cluster"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "stop"   "刪除叢集並停止 system"
	@printf '  $(C_GREEN)%-16s$(C_RESET) %s\n' "config" "顯示 ~/.kube/config"

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

info: check_dep.stamp
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
	@$(call header,建立叢集)
	@$(call run,container k8s create --name hello-cluster)

run: start create
	@$(call header,目前狀態)
	@$(call run,container k8s ls)
	@$(call run,container ls -a)

# stop 之後 ~/.kube/config 的內容也會清除
stop: check_dep.stamp
	@$(call header,停止並清理)
	@$(call run,container k8s rm --name hello-cluster)
	@$(call run,container system stop)
	@$(call ok,已停止)

config:
	@$(call header, ~/.kube/config)
	@printf '$(C_DIM)'
	cat ~/.kube/config
	@printf '$(C_RESET)'
