#!/bin/bash
function error_exit(){
	echo "$1" 1>&2
	exit 1
}

# Install prereqs
function install_Prerequisites(){
	sudo apt -y update
	sudo apt -y upgrade
	sudo apt install -y autoconf bison build-essential ccache file flex \
	g++ git gawk gettext git-core libncurses5-dev libnl-3-200 libnl-3-dev \
	libnl-genl-3-200 libnl-genl-3-dev libssl-dev ncurses-term python \
	quilt sharutils subversion texinfo unzip wget xsltproc zlib1g-dev
	sudo apt-get -y autoremove
}

function download_LEDE_source(){
	cd "$install_dir" || error_exit "Installation directory cannot be found anymore, please git clone batman repo again"
	git clone http://git.lede-project.org/source.git
}

function downloadImageBuilder(){
	echo "Downloading LEDE Image Builder"
	cd "$install_dir" || error_exit "Installation directory cannot be found anymore, please git clone batman repo again"
	wget -N --continue https://downloads.lede-project.org/releases/17.01.0/targets/"${target[$devicetype]}"/"${subtarget[$devicetype]}"/lede-imagebuilder-17.01.0-"${target[$devicetype]}"-"${subtarget[$devicetype]}".Linux-x86_64.tar.xz
	rm -rf lede-imagebuilder-"${target[$devicetype]}"-"${subtarget[$devicetype]}".Linux-x86_64
	tar xf lede-imagebuilder-"${target[$devicetype]}"-"${subtarget[$devicetype]}".Linux-x86_64.tar.xz
}

function install_Feeds(){
	cd "${build_dir[$batman_routing_algo]}" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	git pull
	# update and install feeds
	./scripts/feeds update -a
	./scripts/feeds install -a
}

function config_LEDE(){
	cd "${build_dir[$batman_routing_algo]}" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	cp -f "$install_dir"/"${devicetype[$hostname]}"/diffconfig .config
	make defconfig
}

function downloadNodesTemplateConfigs(){
	cd "$install_dir" || error_exit "Installation directory cannot be found anymore, please git clone batman repo again"
	git pull
}

function substituteVariables(){
	find . -type f -print0 | while IFS= read -r -d $'\0' files;
	do
		sed -i "s/\$batman_routing_algo/'${batman_routing_algo}'/g" "$files"
		sed -i "s/\$radio0_disable/'${radio0_profile[$devicetype]}'/g" "$files"
		sed -i "s/\$radio1_disable/'${radio1_profile[$devicetype]}'/g" "$files"
		sed -i "s/\$adhoc0_disable/'${radio0_adhoc_profile[$devicetype]}'/g" "$files"
		sed -i "s/\$adhoc1_disable/'${radio1_adhoc_profile[$devicetype]}'/g" "$files"
		sed -i "s/\$radio0_ap_disable/'${radio0_ap_profile[$devicetype]}'/g" "$files"
		sed -i "s/\$radio1_ap_disable/'${radio1_ap_profile[$devicetype]}'/g" "$files"
		sed -i "s/\$radio0_channel/'${radio0_channel_profile[$devicetype]}'/g" "$files"
		sed -i "s/\$radio1_channel/'${radio1_channel_profile[$devicetype]}'/g" "$files"
		sed -i "s/\$hostname/'${hostname}'/g" "$files"
		sed -i "s/\$meshssid/'${meshssid}'/g" "$files"
		sed -i "s/\$bssid/'${bssid}'/g" "$files"
		sed -i "s/\$ssid/'${ssid}'/g" "$files"
		sed -i "s/\$wpa2key/'${wpa2key}'/g" "$files"
		sed -i "s/\$mobility_domain/'${mobility_domain}'/g" "$files"
		sed -i "s/\$batman_routing_algo/'${batman_routing_algo}'/g" "$files"
		sed -i "s/\$interface_name/'${interface_name}'/g" "$files"
		sed -i "s/\$interface_mesh_name/'${interface_mesh_name}'/g" "$files"
		sed -i "s/\$interface_ifname0/'${interface_ifname0}'/g" "$files"
		sed -i "s/\$interface_ifname1/'${interface_ifname1}'/g" "$files"
		sed -i "s/\$ip_start/'${ip_start}'/g" "$files"
		sed -i "s/\$number_of_ips/'${number_of_ips}'/g" "$files"
		sed -i "s/\$leasetime/'${leasetime}'/g" "$files"
		sed -i "s/\$lan_ip/'${lan_ip}'/g" "$files"
		sed -i "s/\$lan_netmask/'${lan_netmask}'/g" "$files"
		sed -i "s/\$wan_protocol/'${wan_protocol}'/g" "$files"
		sed -i "s/\$wan_ip/'${wan_ip}'/g" "$files"
		sed -i "s/\$wan_netmask/'${wan_netmask}'/g" "$files"
		sed -i "s/\$wan_gateway/'${wan_gateway}'/g" "$files"
		sed -i "s/\$batman_monitor_ip/'${batman_monitor_ip}'/g" "$files"
		sed -i "s/\$domain/'${domain}'/g" "$files"
		sed -i "s/\$external_dns_ip/'${external_dns_ip}'/g" "$files"
		sed -i "s/\$upstream_domain/'${upstream_domain}'/g" "$files"
		sed -i "s/\$syscontact/'${syscontact}'/g" "$files"
		sed -i "s/\$syslocation/'${syslocation}'/g" "$files"
		sed -i "s/\$upstream_dns/'${upstream_dns}'/g" "$files"
		sed -i "s/\$macfilter/'${macfilter}'/g" "$files"
		sed -i "s/\$maclist/'${maclist}'/g" "$files"
		sed -i "s/\$hide_ap_ssid/'${hide_ap_ssid}'/g" "$files"
		sed -i "s/\$dynamicdhcp/'${dynamicdhcp}'/g" "$files"
	done
}

function createConfigFilesGateway(){
	cd "${build_dir[$batman_routing_algo]}" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	rm -rf files
	mkdir files
	mkdir files/etc
	mkdir files/etc/config
	cd "${build_dir[$batman_routing_algo]}"/files/etc/config || error_exit "LEDE config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/alfred .
	if [ "$batman_routing_algo" == "BATMAN_IV" ]; then
		cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/batman-adv-v4 batman-adv
	fi
	if [ "$batman_routing_algo" == "BATMAN_V" ]; then
		cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/batman-adv-v5 batman-adv
	fi	
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/dhcp .
	if [ "$dynamicdhcp" == "0" ]; then
		cat "$install_dir"/"${devicetype[$hostname]}"/gateway_files/static_leases >> dhcp
	fi	
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/firewall .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/wireless .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/snmpd .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/system .
	if [ "$wan_protocol" == "dhcp" ]; then
		cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/network_wan_dhcp network
	fi
	if [ "$wan_protocol" == "static" ]; then
		cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/network_wan_static network
	fi
	cd "${build_dir[$batman_routing_algo]}"/files/etc || error_exit "LEDE config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/resolv.conf .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/rc.local .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/passwd .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/shadow .
	substituteVariables
}

function createConfigFilesNode(){
	cd "${build_dir[$batman_routing_algo]}" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	rm -rf files
	mkdir files
	mkdir files/etc
	mkdir files/etc/config
	cd "${build_dir[$batman_routing_algo]}"/files/etc/config || error_exit "LEDE config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/alfred .
	if [ "$batman_routing_algo" == "BATMAN_IV" ]; then
		cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/batman-adv-v4 batman-adv
	fi
	if [ "$batman_routing_algo" == "BATMAN_V" ]; then
		cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/batman-adv-v5 batman-adv
	fi	
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/dhcp .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/firewall .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/wireless .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/snmpd .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/network .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/system .
	cd "${build_dir[$batman_routing_algo]}"/files/etc || error_exit "LEDE config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/resolv.conf .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/rc.local .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/passwd .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/shadow .
	substituteVariables
}

function compile_Image(){
	# Compile from source
	rm "${build_dir[$batman_routing_algo]}"/bin/"${target[$devicetype]}"/"${firmware_name_compile[$devicetype]}"
	cd "${build_dir[$batman_routing_algo]}" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	make -j"${nproc}" V=s
}

function build_Image(){
	echo "Building LEDE image with config files"
	# Make LEDE Firmware for specified platform using config files above
	cd "${build_dir[$batman_routing_algo]}" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	make image PROFILE="${profile[$devicetype]}" PACKAGES="${packages[$devicetype]}" FILES=files/
}

function check_Firmware_imagebuilder(){
	# CHECK SHA256 OF COMPILED IMAGE
	export build_successfull='0'
	export checksum_OK='0'
	echo "${build_dir[$batman_routing_algo]}"/bin/targets/"${target[$devicetype]}"/"${subtarget[$devicetype]}"/"${firmware_name_imagebuilder[$devicetype]}"
	cd "${build_dir[$batman_routing_algo]}"/bin/targets/"${target[$devicetype]}"/"${subtarget[$devicetype]}" || error_exit "firmware not found, check available disk space"
	if [ -f "${firmware_name_imagebuilder[$devicetype]}" ]; then
		echo "Compilation Successfull"
		export build_successfull='1'
	else
		error_exit "Errors found during compilation, firmware not found, check build log on screen for errors"
	fi
	if [ $build_successfull -eq '1' ]; then
		if grep "${firmware_name_imagebuilder[$devicetype]}" sha256sums | tee /proc/self/fd/2 | sha256sum --check - ; then
			echo "Checksum OK"
			export checksum_OK='1'
		else
			error_exit "Firmware checksum is incorrect, aborting! Check internet connection and available disk space"
		fi
	fi
}

function copy_Firmware_imagebuilder(){
	cd "${build_dir[$batman_routing_algo]}"/bin/targets/"${target[$devicetype]}"/"${subtarget[$devicetype]}" || error_exit "firmware not found, check available disk space"
	if [[ $build_successfull -eq '1' && $checksum_OK -eq '1' ]] ; then
		cp "${firmware_name_imagebuilder[$devicetype]}" "$install_dir"/firmwares/"$hostname".bin
		rm "${firmware_name_imagebuilder[$devicetype]}"
	else
		error_exit "Problems found trying to deliver firmware to output directory, check available disk space"
	fi
}

function check_Firmware_compile(){
	# CHECK SHA256 OF COMPILED IMAGE
	export build_successfull='0'
	export checksum_OK='0'
	echo "${build_dir[$batman_routing_algo]}"/bin/targets/"${target[$devicetype]}"/"${subtarget[$devicetype]}"/"${firmware_name_compile[$devicetype]}"
	cd "${build_dir[$batman_routing_algo]}"/bin/targets/"${target[$devicetype]}"/"${subtarget[$devicetype]}" || error_exit "firmware not found, check available disk space"
	if [ -f "${firmware_name_compile[$devicetype]}" ]; then
		echo "Compilation Successfull"
		export build_successfull='1'
	else
		error_exit "Errors found during compilation, firmware not found, check build log on screen for errors"
	fi
	if [ $build_successfull -eq '1' ]; then
		if grep "${firmware_name_compile[$devicetype]}" sha256sums | tee /proc/self/fd/2 | sha256sum --check - ; then
			echo "Checksum OK"
			export checksum_OK='1'
		else
			error_exit "Firmware checksum is incorrect, aborting! Check internet connection and available disk space"
		fi
	fi
}

function copy_Firmware_compile(){
	cd "${build_dir[$batman_routing_algo]}"/bin/targets/"${target[$devicetype]}"/"${subtarget[$devicetype]}" || error_exit "firmware not found, check available disk space"
	if [[ $build_successfull -eq '1' && $checksum_OK -eq '1' ]] ; then
		cp "${firmware_name_compile[$devicetype]}" "$install_dir"/firmwares/"$hostname".bin
		rm "${firmware_name_compile[$devicetype]}"
	else
		error_exit "Problems found trying to deliver firmware to output directory, check available disk space"
	fi
}
