# Makefile for managing Kubernetes VMs with Ansible
SHELL := /bin/bash
PLAYBOOK_DIR := $(shell pwd)
_ := $(shell sed -i 's|^PLAYBOOK_DIR:.*|PLAYBOOK_DIR: $(PLAYBOOK_DIR)|' facts/infra.yaml)

# Playbooks
00_DESTROY_PLAYBOOK = 00.remove_vms.yaml
01_CREATE_PLAYBOOK = 01.create_vms.yaml
02_CONFIGURE_SSH = 02.configure_ssh.yaml
03_CONFIGURE_PLAYBOOK = 03.configure.yaml
10_K8S_PLAYBOOK = 10.k8s.yaml
20_STORAGE_CEPH_PLAYBOOK = 20.storage_ceph.yaml
20_STORAGE_GLUSTERFS_PLAYBOOK = 20.storage_glusterfs.yaml
20_STORAGE_CEPH_ROOK_PLAYBOOK = 20.storage_rook_ceph.yaml
20_STORAGE_NFS_PV_PLAYBOOK = 20.storage.nfs_pv.yaml
25_HARBOR_PLAYBOOK = 25.harbor.registry.yaml
27_GRAFANA_PROMETHOUS_PLAYBOOK = 27.grafana-prometheus.yaml
30_MEDIA_CENTER_PLAYBOOK = 30.media_center.yaml
90_K8SLOCAL_PLAYBOOK = 90.k8s_local.yaml

INVENTORY_SCRIPT = inventory/libvirt_inventory.py 
INVENTORY = inventory.ini 
BASIC_AUTH = --user root --extra-vars "ansible_ssh_pass=123456"

# Targets
.PHONY: all destroy create prep k8s k8s-local nfs harbor grafnaprom mediacenter

all: destroy create prep k8s k8s-local nfs harbor grafnaprom mediacenter

postcreate: prep k8s

destroy:
	sudo ansible-playbook $(PLAYBOOK_DIR)/$(00_DESTROY_PLAYBOOK)

create:
	sudo ansible-playbook $(PLAYBOOK_DIR)/$(01_CREATE_PLAYBOOK)

prep:
	python3 ${PLAYBOOK_DIR}/${INVENTORY_SCRIPT} > ./inventory/inventory.ini
	ansible-playbook ${02_CONFIGURE_SSH} ${BASIC_AUTH}
	ansible-playbook ${03_CONFIGURE_PLAYBOOK}

k8s:
	ansible-playbook ${10_K8S_PLAYBOOK}

k8s-local:
	rm -rvf ~/.kube/confg
	ansible-playbook ${90_K8SLOCAL_PLAYBOOK}

ceph:
	ansible-playbook ${20_STORAGE_CEPH_PLAYBOOK}

ceph-rook:
	ansible-playbook ${20_STORAGE_CEPH_ROOK_PLAYBOOK}

glusterfs:
	ansible-playbook ${20_STORAGE_GLUSTERFS_PLAYBOOK}

nfs:
	ansible-playbook ${20_STORAGE_NFS_PV_PLAYBOOK}

harbor:
	ansible-playbook ${25_HARBOR_PLAYBOOK}

grafnaprom:
	ansible-playbook ${27_GRAFANA_PROMETHOUS_PLAYBOOK}

mediacenter:
	ansible-playbook ${30_MEDIA_CENTER_PLAYBOOK}

helm:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
	helm install grafana grafana/grafana --namespace monitoring

helm-package:
	{ \
		cd helm && helm package . ; \
		cd .. ; \
	}

helm-deploy:
	{ \
		cd helm; \
		helm delete k8s-media-center; \
		helm install k8s-media-center k8s-media-center-0.1.0.tgz ; \
		cd .. ; \
	}
