#!/usr/bin/env python3
import libvirt
import time

def list_domain_ips():
    conn = libvirt.open("qemu:///system")
    if conn is None:
        print('Failed to open connection to qemu:///system', file=sys.stderr)
        exit(1)
    
    while True:
        domains = conn.listAllDomains()
        ips = {}
        for domain in domains:
            name = domain.name()
            if "k8s" in name:
                ip = domain.interfaceAddresses(libvirt.VIR_DOMAIN_INTERFACE_ADDRESSES_SRC_LEASE)
                if ip:
                    ips[name] = [addr['addrs'][0]['addr'] for addr in ip.values()][0]  # Only first IP address is considered
        
        if len(ips) == 3:  # Check if all three hosts are available
            break
        
        time.sleep(5)  # Wait for 5 seconds before checking again
    
    conn.close()
    return ips

def main():
    ips = list_domain_ips()
    print("[vms]")
    for name, ip in sorted(ips.items()):
        print(f"{name} ansible_host={ip} ansible_user=root")
    
    print("")
    print("[master]")
    for name, ip in sorted(ips.items()):
        print(f"{name} ansible_host={ip} ansible_user=root")
        break

    print("")
    print("[slaves]")
    skip = True
    for name, ip in sorted(ips.items()):
        if skip:
            skip = False
            continue
        print(f"{name} ansible_host={ip} ansible_user=root")

    print("")
    print("[local]")
    print("localhost ansible_connection=local")

if __name__ == "__main__":
    main()
