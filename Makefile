# Makefile for managing Kubernetes VMs with Ansible
SHELL := /bin/bash
PLAYBOOK_DIR := $(shell pwd)
_ := $(shell sed -i 's|^PLAYBOOK_DIR:.*|PLAYBOOK_DIR: $(PLAYBOOK_DIR)|' facts/infra.yaml)

# Playbooks
050_BUILD_BASE_QCOW_PLAYBOOK = 050.create_base_qcow.yaml
060_HOST_SETUP_PLAYBOOK = 060.host_setup.yaml
100_DESTROY_PLAYBOOK = 100.remove_vms.yaml
110_CREATE_PLAYBOOK = 110.create_vms.yaml
120_CONFIGURE_SSH = 120.configure_ssh.yaml
130_CONFIGURE_PLAYBOOK = 130.configure.yaml
300_K8S_PLAYBOOK = 300.k8s.yaml
400_STORAGE_CEPH_PLAYBOOK = 400.storage_ceph.yaml
410_STORAGE_GLUSTERFS_PLAYBOOK = 410.storage_glusterfs.yaml
420_STORAGE_CEPH_ROOK_PLAYBOOK = 420.storage_rook_ceph.yaml
430_STORAGE_NFS_PV_PLAYBOOK = 430.storage.nfs_pv.yaml
600_HARBOR_PLAYBOOK = 600.harbor.registry.yaml
700_GRAFANA_PROMETHOUS_PLAYBOOK = 700.grafana-prometheus.yaml
710_CADVISOR_PLAYBOOK = 710.cadvisor.yaml
800_MEDIA_CENTER_PLAYBOOK = 800.media_center.yaml
900_K8SLOCAL_PLAYBOOK = 900.k8s_local.yaml

INVENTORY_SCRIPT = inventory/libvirt_inventory.py 
INVENTORY = inventory.ini 
BASIC_AUTH = --user root --extra-vars "ansible_ssh_pass=123456"

# Targets
.PHONY: all destroy create inventory ssh prep k8s k8s-local nfs harbor cadvisor grafanaprom mediacenter

all: destroy create inventory ssh prep k8s k8s-local nfs harbor cadvisor grafanaprom mediacenter

postcreate: inventory prep k8s

destroy:
	sudo ansible-playbook $(PLAYBOOK_DIR)/$(100_DESTROY_PLAYBOOK)

create:
	sudo ansible-playbook $(PLAYBOOK_DIR)/$(110_CREATE_PLAYBOOK)

inventory:
	python3 ${PLAYBOOK_DIR}/${INVENTORY_SCRIPT} > ./inventory/inventory.ini

ssh:
	ansible-playbook ${120_CONFIGURE_SSH} ${BASIC_AUTH}

prep:		
	ansible-playbook ${130_CONFIGURE_PLAYBOOK}

k8s:
	ansible-playbook ${300_K8S_PLAYBOOK}

ceph:
	ansible-playbook ${400_STORAGE_CEPH_PLAYBOOK}

ceph-rook:
	ansible-playbook ${420_STORAGE_CEPH_ROOK_PLAYBOOK}

glusterfs:
	ansible-playbook ${410_STORAGE_GLUSTERFS_PLAYBOOK}

nfs:
	ansible-playbook ${430_STORAGE_NFS_PV_PLAYBOOK}

harbor:
	ansible-playbook ${600_HARBOR_PLAYBOOK}

grafanaprom:
	ansible-playbook ${700_GRAFANA_PROMETHOUS_PLAYBOOK}

cadvisor:
	ansible-playbook ${710_CADVISOR_PLAYBOOK}

mediacenter:
	ansible-playbook ${800_MEDIA_CENTER_PLAYBOOK}

k8s-local:
	rm -rvf ~/.kube/confg
	ansible-playbook ${900_K8SLOCAL_PLAYBOOK}

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

host-setup:
	ansible-playbook ${060_HOST_SETUP_PLAYBOOK}

build-base-qcow:
	ansible-playbook ${050_BUILD_BASE_QCOW_PLAYBOOK}
