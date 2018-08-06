#!/bin/bash

export hostname=gateway

# Retrieve current directory
install_dir=$(pwd)

# Read configurations
echo "Reading mesh configs...." >&2
. mesh_configs.cfg

# Read functions
echo "Reading mesh functions...." >&2
. mesh_functions.sh

# create directory for firmwares output
if [ -d "$install_dir"/firmwares ]; then
	cd "$install_dir"/firmwares && rm ./*.bin
else
	mkdir "$install_dir"/firmwares
fi

# FIRMWARE GENERATION PROCESS
update_Ubuntu
install_Prerequisites
case ${lede_options[build_mode]} in
	build)
		build_dir="$install_dir"/openwrt-imagebuilder-"${lede_options[lede_version]}"-"${target[${devicetype[$hostname]}]}"-"${subtarget[${devicetype[$hostname]}]}".Linux-x86_64
		downloadImageBuilder
                export nasid=${mac_address[$hostname]}
                export r1_key_holder=${mac_address[$hostname]}
		createConfigFilesGateway
		build_Image
		check_Firmware_imagebuilder
		copy_Firmware_imagebuilder
		for ((i=1; i<=numberofnodes; i++)); do
			export hostname=node-$i
			export syslocation=${gps_coordinates[$hostname]}
			export nasid=${mac_address[$hostname]}
			export r1_key_holder=${mac_address[$hostname]}
			build_dir="$install_dir"/lede-imagebuilder-"${lede_options[lede_version]}"-"${target[${devicetype[$hostname]}]}"-"${subtarget[${devicetype[$hostname]}]}".Linux-x86_64
			downloadImageBuilder
			createConfigFilesNode
			build_Image
			check_Firmware_imagebuilder
			copy_Firmware_imagebuilder
		done
		;;
	compile)
		build_dir=$install_dir/source
		download_LEDE_source
		install_Feeds
                export nasid=${mac_address[$hostname]}
                export r1_key_holder=${mac_address[$hostname]}
		config_LEDE
		downloadNodesTemplateConfigs
		createConfigFilesGateway
		compile_Image
		check_Firmware_compile
		copy_Firmware_compile
		for ((i=1; i<=numberofnodes; i++)); do
			export hostname=node-$i
			export syslocation=${gps_coordinates[$hostname]}
			export nasid=${mac_address[$hostname]}
			export r1_key_holder=${mac_address[$hostname]}
			config_LEDE
			createConfigFilesNode
			compile_Image
			check_Firmware_compile
			copy_Firmware_compile
		done
		;;
	*)
		error_exit "check lede config - build mode setting, it is wrong"
esac
echo "Firmware files are bellow"
echo "on directory $install_dir/firmwares"
cd "$install_dir"/firmwares && ls -l ./*.bin
