#!/usr/bin/env python3
"""Dynamic Ansible inventory built from the k8s libvirt VMs' DHCP leases."""

import sys
import time

import libvirt

EXPECTED_HOSTS = 3
POLL_SECONDS = 5
LEASE_SOURCE = libvirt.VIR_DOMAIN_INTERFACE_ADDRESSES_SRC_LEASE


def list_domain_ips():
    """Wait until all k8s VMs have a leased IP and return {name: ip}."""
    conn = libvirt.open("qemu:///system")
    if conn is None:
        print("Failed to open connection to qemu:///system", file=sys.stderr)
        sys.exit(1)

    while True:
        ips = {}
        for domain in conn.listAllDomains():
            name = domain.name()
            if "k8s" not in name:
                continue
            addresses = domain.interfaceAddresses(LEASE_SOURCE)
            if addresses:
                # Only the first IP address of the first interface is used.
                first = next(iter(addresses.values()))
                ips[name] = first["addrs"][0]["addr"]

        if len(ips) == EXPECTED_HOSTS:
            break

        time.sleep(POLL_SECONDS)

    conn.close()
    return ips


def print_group(group, hosts):
    """Print one inventory group with its hosts."""
    print(f"[{group}]")
    for name, ip in hosts:
        print(f"{name} ansible_host={ip} ansible_user=root")
    print()


def main():
    """Print the inventory in INI format."""
    hosts = sorted(list_domain_ips().items())
    print_group("vms", hosts)
    print_group("master", hosts[:1])
    print_group("slaves", hosts[1:])
    print("[local]")
    print("localhost ansible_connection=local")


if __name__ == "__main__":
    main()
