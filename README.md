Batman advanced mesh project with LEDE (Linux Embedded Development Environment) nodes.

The objective here is to evaluate robustness and performance of a batman-adv mesh using inexpensive equipment. Feedback is always welcome ;)

This project involves the following contents:

Mesh nodes built on LEDE-capable wireless routers (TP-LINK WDR-3600 and WR740, D-LINK DIR-505 and DIR-810, Ubiquiti UnifiAP-LR, UnifiAP and NanoLocoM5)

The mesh nodes run LEDE with batman-adv mesh protocol which creates a giant mesh "L2 bridge" with all nodes; current configuration uses both radios (2.4GHz and 5GHz, where available) as adhoc interfaces. Both radios can be configured also as access points to serve wireless (non-mesh) clients. Wired LAN ports of all routers are bridged too via linux-bridge.

Only one of the nodes (the gateway node) must be connected to a wired network segment with internet connectivity to establish a backhaul exit. The gateway node also provide DHCP and DNS server service for all mesh-nodes and wireless clients.

To generate the firmware for all nodes, first clone this repository and configure variables for number of nodes, IP ranges, WiFi channel selection, etc on mesh_configs.cfg, then turn batman_firmware_generator.sh to executable via chmod +x and execute it.

Build environment tested on Ubuntu Server 14.04 64 bits, all dependencies will be downloaded by the script.

Both versions of batman-adv are supported, version 4 is the stable one and firmware will be generated via LEDE make image process which runs on less than 10 minutes. Version 5 is the development version and firmware has to be compiled from source, as such, build time can take more than 2 hours.

Have fun turning your inexpensive wireless hardware into an advanced mesh!
