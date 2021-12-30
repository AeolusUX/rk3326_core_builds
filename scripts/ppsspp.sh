#!/bin/bash
cur_wd="$PWD"
bitness="$(getconf LONG_BIT)"

	# PPSSPP Standalone build
	if [[ "$var" == "ppsspp" ]] && [[ "$bitness" == "64" ]]; then
	 cd $cur_wd

	  # Now we'll start the clone and build of PPSSPP
	  if [ ! -d "ppsspp/" ]; then
		git clone https://github.com/hrydgard/ppsspp.git --recursive

		if [[ $? != "0" ]]; then
		  echo " "
		  echo "There was an error while cloning the ppsspp standalone git.  Is Internet active or did the git location change?  Stopping here."
		  exit 1
		fi
		cp patches/ppsspp-patch* ppsspp/.
	  else
		echo " "
		echo "A ppsspp subfolder already exists.  Stopping here to not impact anything in the folder that may be needed.  If not needed, please remove the ppsspp folder and rerun this script."
		echo " "
		exit 1
	  fi

	 # Ensure dependencies are installed and available
     neededlibs=( libx11-dev libsm-dev libxext-dev git cmake mercurial libudev-dev libdrm-dev zlib1g-dev pkg-config libasound2-dev libfreetype6-dev libx11-xcb1 libxcb-dri2-0 )
     updateapt="N"
     for libs in "${neededlibs[@]}"
     do
          dpkg -s "${libs}" &>/dev/null
          if [[ $? != "0" ]]; then
           if [[ "$updateapt" == "N" ]]; then
            apt-get -y update
            updateapt="Y"
           fi
           apt-get -y install "${libs}"
           if [[ $? != "0" ]]; then
            echo " "
            echo "Could not install needed library ${libs}.  Stopping here so this can be reviewed."
            exit 1
           fi
          fi
     done

	 cd ppsspp/ffmpeg
	 ./linux_arm64.sh
	 cd ..
	 
	 ppsspp_patches=$(find *.patch)
	 
	 if [[ ! -z "$ppsspp_patches" ]]; then
	  for patching in ppsspp-patch*
	  do
		   patch -Np1 < "$patching"
		   if [[ $? != "0" ]]; then
			echo " "
			echo "There was an error while applying $patching.  Stopping here."
			exit 1
		   fi
		   rm "$patching" 
	  done
	 fi

	  mkdir build
	  cd build
	  cmake -DUSING_EGL=OFF -DUSING_GLES2=ON -DUSE_FFMPEG=YES -DUSE_SYSTEM_FFMPEG=NO -DUSING_X11_VULKAN=OFF -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -fpermissive ../.
	  make -j$(($(nproc) - 1))

	  if [[ $? != "0" ]]; then
		echo " "
		echo "There was an error while building the newest ppsspp standalone.  Stopping here."
		exit 1
	  fi

	  strip PPSSPPSDL

	  if [ ! -d "../../ppsspp$bitness/" ]; then
		mkdir -v ../../ppsspp$bitness
	  fi

	  cp PPSSPPSDL ../../ppsspp$bitness/.
	  tar -zchvf ../../ppsspp$bitness/ppssppsdl_pkg_$(git rev-parse HEAD | cut -c -7).tar.gz assets/ PPSSPPSDL

	  echo " "
	  echo "PPSSPPSDL executable and ppssppsdl_pkg_$(git rev-parse HEAD | cut -c -7).tar.gz package has been created and has been placed in the rk3326_core_builds/ppsspp$bitness subfolder"

	fi
