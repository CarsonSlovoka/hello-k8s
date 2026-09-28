SHELL := /bin/bash

.SHELLFLAGS := -eu -o pipefail -c

REQUIRED_PACKAGES = kubectl kind container

.ONESHELL:
.PHONY: all help info check_dep run start create

help:
	@echo "Targets:"
	@echo "  info              查看container版本"

check_dep:
	@for pkg in $(REQUIRED_PACKAGES); do \
		echo "檢查: $$pkg"; \
		if ! brew list $$pkg >/dev/null 2>&1; then \
			echo "⚠️  發現未安裝 $$pkg，正在自動安裝..."; \
			brew install $$pkg || exit 1; \
		fi; \
	done
	touch check_dep.stamp

# container k8s 是 experimental，子指令名稱可能因版本略有不同, 所以要確認版本
info: check_dep.stamp
	container --version  >  k8s.txt
	container k8s --help >> k8s.txt

start:
	container system start

create:
	container k8s create --name hello-cluster

run: start create
	container k8s ls
	container ls -a

stop: check_dep.stamp
	container k8s rm     --name hello-cluster
	container system stop

config:
	cat ~/.kube/config
