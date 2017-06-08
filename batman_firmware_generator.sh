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
install_Prerequisites
case $build_mode in
	build)
		declare -A build_dir=( [build]="$install_dir"/lede-imagebuilder-17.01.0-"${target[${devicetype[$hostname]}]}"-"${subtarget[${devicetype[$hostname]}]}".Linux-x86_64 )
		downloadImageBuilder
		createConfigFilesGateway
		build_Image
		check_Firmware_imagebuilder
		copy_Firmware_imagebuilder
		for ((i=1; i<=numberofnodes; i++)); do
			export hostname=node-$i
			export syslocation=${gps_coordinates[$hostname]}
			declare -A build_dir=( [build]="$install_dir"/lede-imagebuilder-17.01.0-"${target[${devicetype[$hostname]}]}"-"${subtarget[${devicetype[$hostname]}]}".Linux-x86_64 )
			downloadImageBuilder
			createConfigFilesNode
			build_Image
			check_Firmware_imagebuilder
			copy_Firmware_imagebuilder
		done
		;;
	compile)
		declare -r -A build_dir=( [compile]=$install_dir/source )
		download_LEDE_source
		install_Feeds
		config_LEDE
		downloadNodesTemplateConfigs
		createConfigFilesGateway
		compile_Image
		check_Firmware_compile
		copy_Firmware_compile
		for ((i=1; i<=numberofnodes; i++)); do
			export hostname=node-$i
			export syslocation=${gps_coordinates[$hostname]}
			config_LEDE
			createConfigFilesNode
			compile_Image
			check_Firmware_compile
			copy_Firmware_compile
		done
		;;
	*)
		error_exit "check batman protocol version selection, it is wrong"
esac
echo "Firmware files are bellow"
echo "on directory $install_dir/firmwares"
cd "$install_dir"/firmwares && ls -l ./*.bin
