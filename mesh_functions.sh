#!/bin/bash
function error_exit(){
	echo "$1" 1>&2
	exit 1
}

# Update ubuntu
function update_Ubuntu(){
        TODAY=$(date +%s)
        UPDATE_TIME=$(date +%s -r /var/cache/apt/pkgcache.bin)
        DELTA_TIME="$(echo "$TODAY - $UPDATE_TIME" | bc)"
        if [ $DELTA_TIME -ge 100000 ]; then
                sudo apt -y update
                sudo apt -y upgrade
        fi
}

# Install prereqs
function install_Prerequisites(){
	sudo apt install -y autoconf bison build-essential ccache file flex \
	g++ git gawk gettext git-core libncurses5-dev libnl-3-200 libnl-3-dev \
	libnl-genl-3-200 libnl-genl-3-dev libssl-dev ncurses-term python \
	quilt sharutils subversion texinfo unzip wget xsltproc zlib1g-dev bc
	sudo apt-get -y autoremove
}

function download_LEDE_source(){
	cd "$install_dir" || error_exit "Installation directory cannot be found anymore, please git clone batman repo again"
	git clone http://git.lede-project.org/source.git
	cd source
	git fetch origin
	git checkout "${lede_options[git_checkout_branch]}"
	git pull
}

function downloadImageBuilder(){
	echo "Downloading LEDE Image Builder"
	cd "$install_dir" || error_exit "Installation directory cannot be found anymore, please git clone batman repo again"
	wget -N --continue https://downloads.lede-project.org/releases/"${lede_options[lede_version]}"/targets/"${target[${devicetype[$hostname]}]}"/"${subtarget[${devicetype[$hostname]}]}"/lede-imagebuilder-"${lede_options[lede_version]}"-"${target[${devicetype[$hostname]}]}"-"${subtarget[${devicetype[$hostname]}]}".Linux-x86_64.tar.xz
	rm -rf lede-imagebuilder-"${lede_options[lede_version]}"-"${target[${devicetype[$hostname]}]}"-"${subtarget[${devicetype[$hostname]}]}".Linux-x86_64
	tar xf lede-imagebuilder-"${lede_options[lede_version]}"-"${target[${devicetype[$hostname]}]}"-"${subtarget[${devicetype[$hostname]}]}".Linux-x86_64.tar.xz
}

function install_Feeds(){
	cd "$build_dir" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	git pull
	# update and install feeds
	./scripts/feeds update -a
	./scripts/feeds install -a
}

function config_LEDE(){
	cd "$build_dir" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	cp -f "$install_dir"/"${devicetype[$hostname]}"/diffconfig .config
	make defconfig
}

function downloadNodesTemplateConfigs(){
	cd "$install_dir" || error_exit "Installation directory cannot be found anymore, please git clone batman repo again"
	git pull
}

function substituteVariables(){
	cd "$build_dir"/files
	find . -type f -print0 | while IFS= read -r -d $'\0' files;
	do
		sed -i "s/\$radio0_disable/'${radio0_profile[${devicetype[$hostname]}]}'/g" "$files"
		sed -i "s/\$radio1_disable/'${radio1_profile[${devicetype[$hostname]}]}'/g" "$files"
		sed -i "s/\$adhoc0_disable/'${radio0_adhoc_profile[${devicetype[$hostname]}]}'/g" "$files"
		sed -i "s/\$adhoc1_disable/'${radio1_adhoc_profile[${devicetype[$hostname]}]}'/g" "$files"
		sed -i "s/\$radio0_ap_disable/'${radio0_ap_profile[${devicetype[$hostname]}]}'/g" "$files"
		sed -i "s/\$radio1_ap_disable/'${radio1_ap_profile[${devicetype[$hostname]}]}'/g" "$files"
		sed -i "s/\$radio0_channel/'${radio0_channel_profile[${devicetype[$hostname]}]}'/g" "$files"
		sed -i "s/\$radio1_channel/'${radio1_channel_profile[${devicetype[$hostname]}]}'/g" "$files"
		sed -i "s/\$hostname/'${hostname}'/g" "$files"
		sed -i "s/\$meshssid/${mesh_config[meshssid]}/g" "$files"
		sed -i "s/\$bssid/${mesh_config[bssid]}/g" "$files"
		sed -i "s/\$ssid/${mesh_config[ssid]}/g" "$files"
		sed -i "s/\$wpa2key/${mesh_config[wpa2key]}/g" "$files"
		sed -i "s/\$mobility_domain/${mesh_config[mobility_domain]}/g" "$files"
		sed -i "s/\$batman_routing_algo/${mesh_config[batman_routing_algo]}/g" "$files"
		sed -i "s/\$interface_name/${mesh_config[interface_name]}/g" "$files"
		sed -i "s/\$interface_mesh_name/${mesh_config[interface_mesh_name]}/g" "$files"
		sed -i "s/\$interface_ifname0/${mesh_config[interface_ifname0]}/g" "$files"
		sed -i "s/\$interface_ifname1/${mesh_config[interface_ifname1]}/g" "$files"
		sed -i "s/\$ip_start/${net_config[ip_start]}/g" "$files"
		sed -i "s/\$number_of_ips/${net_config[number_of_ips]}/g" "$files"
		sed -i "s/\$leasetime/${net_config[leasetime]}/g" "$files"
		sed -i "s/\$lan_ip/${net_config[lan_ip]}/g" "$files"
		sed -i "s/\$lan_netmask/${net_config[lan_netmask]}/g" "$files"
		sed -i "s/\$wan_protocol/${net_config[wan_protocol]}/g" "$files"
		sed -i "s/\$wan_ip/${net_config[wan_ip]}/g" "$files"
		sed -i "s/\$wan_netmask/${net_config[wan_netmask]}/g" "$files"
		sed -i "s/\$wan_gateway/${net_config[wan_gateway]}/g" "$files"
		sed -i "s/\$batman_monitor_ip/${net_config[batman_monitor_ip]}/g" "$files"
		sed -i "s/\$domain/${net_config[domain]}/g" "$files"
		sed -i "s/\$external_dns_ip/${net_config[external_dns_ip]}/g" "$files"
		sed -i "s/\$upstream_domain/${net_config[upstream_domain]}/g" "$files"
		sed -i "s/\$syscontact/${net_config[syscontact]}/g" "$files"
		sed -i "s/\$syslocation/'${syslocation}'/g" "$files"
		sed -i "s/\$upstream_dns/${net_config[upstream_dns]}/g" "$files"
		sed -i "s/\$macfilter/${net_config[macfilter]}/g" "$files"
		sed -i "s/\$maclist/${net_config[maclist]}/g" "$files"
		sed -i "s/\$hide_ap_ssid/${mesh_config[hide_ap_ssid]}/g" "$files"
		sed -i "s/\$dynamicdhcp/${net_config[dynamicdhcp]}/g" "$files"
		sed -i "s/\$nasid/${nasid}/g" "$files"
		sed -i "s/\$r1_key_holder/${r1_key_holder}/g" "$files"
	done
}

function createConfigFilesGateway(){
	cd "$build_dir" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	rm -rf files
	mkdir files
	mkdir files/etc
	mkdir files/etc/config
	mkdir files/etc/crontabs
	cd "$build_dir"/files/etc/config || error_exit "LEDE config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/alfred .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/adblock .
	if [ "${mesh_config[batman_routing_algo]}" == "BATMAN_IV" ]; then
		cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/batman-adv-v4 batman-adv
	fi
	if [ "${mesh_config[batman_routing_algo]}" == "BATMAN_V" ]; then
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
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/sqm .
	if [ "${net_config[wan_protocol]}" == "dhcp" ]; then
		cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/network_wan_dhcp network
	fi
	if [ "${net_config[wan_protocol]}" == "static" ]; then
		cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/network_wan_static network
	fi
	cd "$build_dir"/files/etc || error_exit "LEDE config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/resolv.conf .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/rc.local .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/passwd .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/shadow .
	cd "$build_dir"/files/etc/crontabs || error_exit "LEDE config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"${devicetype[$hostname]}"/gateway_files/root .
	substituteVariables
}

function createConfigFilesNode(){
	cd "$build_dir" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	rm -rf files
	mkdir files
	mkdir files/etc
	mkdir files/etc/config
	cd "$build_dir"/files/etc/config || error_exit "LEDE config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/alfred .
	if [ "${mesh_config[batman_routing_algo]}" == "BATMAN_IV" ]; then
		cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/batman-adv-v4 batman-adv
	fi
	if [ "${mesh_config[batman_routing_algo]}" == "BATMAN_V" ]; then
		cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/batman-adv-v5 batman-adv
	fi	
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/dhcp .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/firewall .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/wireless .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/snmpd .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/network .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/system .
	cd "$build_dir"/files/etc || error_exit "LEDE config directory cannot be found, please check write permissions on this directory"
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/resolv.conf .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/rc.local .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/passwd .
	cp -f "$install_dir"/"${devicetype[$hostname]}"/nodes_files/shadow .
	substituteVariables
}

function compile_Image(){
	# Compile from source
	rm "$build_dir"/bin/"${target[${devicetype[$hostname]}]}"/"${firmware_name_compile[${devicetype[$hostname]}]}"
	cd "$build_dir" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	make -j"${nproc}" V=s
}

function build_Image(){
	echo "Building LEDE image with config files"
	# Make LEDE Firmware for specified platform using config files above
	cd "$build_dir" || error_exit "Build directory cannot be found anymore, please check internet connection and rerun script"
	make image PROFILE="${profile[${devicetype[$hostname]}]}" PACKAGES="${packages[${devicetype[$hostname]}]}" FILES=files/
}

function check_Firmware_imagebuilder(){
	# CHECK SHA256 OF COMPILED IMAGE
	export build_successfull='0'
	export checksum_OK='0'
	echo "$build_dir"/bin/targets/"${target[${devicetype[$hostname]}]}"/"${subtarget[${devicetype[$hostname]}]}"/"${firmware_name_imagebuilder[${devicetype[$hostname]}]}"
	cd "$build_dir"/bin/targets/"${target[${devicetype[$hostname]}]}"/"${subtarget[${devicetype[$hostname]}]}" || error_exit "firmware not found, check available disk space"
	if [ -f "${firmware_name_imagebuilder[${devicetype[$hostname]}]}" ]; then
		echo "Compilation Successfull"
		export build_successfull='1'
	else
		error_exit "Errors found during compilation, firmware not found, check build log on screen for errors"
	fi
	if [ $build_successfull -eq '1' ]; then
		if grep "${firmware_name_imagebuilder[${devicetype[$hostname]}]}" sha256sums | tee /proc/self/fd/2 | sha256sum --check - ; then
			echo "Checksum OK"
			export checksum_OK='1'
		else
			error_exit "Firmware checksum is incorrect, aborting! Check internet connection and available disk space"
		fi
	fi
}

function copy_Firmware_imagebuilder(){
	cd "$build_dir"/bin/targets/"${target[${devicetype[$hostname]}]}"/"${subtarget[${devicetype[$hostname]}]}" || error_exit "firmware not found, check available disk space"
	if [[ $build_successfull -eq '1' && $checksum_OK -eq '1' ]] ; then
		cp "${firmware_name_imagebuilder[${devicetype[$hostname]}]}" "$install_dir"/firmwares/"$hostname".bin
		rm "${firmware_name_imagebuilder[${devicetype[$hostname]}]}"
	else
		error_exit "Problems found trying to deliver firmware to output directory, check available disk space"
	fi
}

function check_Firmware_compile(){
	# CHECK SHA256 OF COMPILED IMAGE
	export build_successfull='0'
	export checksum_OK='0'
	echo "$build_dir"/bin/targets/"${target[${devicetype[$hostname]}]}"/"${subtarget[${devicetype[$hostname]}]}"/"${firmware_name_compile[${devicetype[$hostname]}]}"
	cd "$build_dir"/bin/targets/"${target[${devicetype[$hostname]}]}"/"${subtarget[${devicetype[$hostname]}]}" || error_exit "firmware not found, check available disk space"
	if [ -f "${firmware_name_compile[${devicetype[$hostname]}]}" ]; then
		echo "Compilation Successfull"
		export build_successfull='1'
	else
		error_exit "Errors found during compilation, firmware not found, check build log on screen for errors"
	fi
	if [ $build_successfull -eq '1' ]; then
		if grep "${firmware_name_compile[${devicetype[$hostname]}]}" sha256sums | tee /proc/self/fd/2 | sha256sum --check - ; then
			echo "Checksum OK"
			export checksum_OK='1'
		else
			error_exit "Firmware checksum is incorrect, aborting! Check internet connection and available disk space"
		fi
	fi
}

function copy_Firmware_compile(){
	cd "$build_dir"/bin/targets/"${target[${devicetype[$hostname]}]}"/"${subtarget[${devicetype[$hostname]}]}" || error_exit "firmware not found, check available disk space"
	if [[ $build_successfull -eq '1' && $checksum_OK -eq '1' ]] ; then
		cp "${firmware_name_compile[${devicetype[$hostname]}]}" "$install_dir"/firmwares/"$hostname".bin
		rm "${firmware_name_compile[${devicetype[$hostname]}]}"
	else
		error_exit "Problems found trying to deliver firmware to output directory, check available disk space"
	fi
}
