#!/bin/bash

##################################################################
# Created by Christian Haitian for use to easily update          #
# various standalone emulators, libretro cores, and other        #
# various programs for the RK3326 platform for various Linux     #
# based distributions.                                           #
# See the LICENSE.md file at the top-level directory of this     #
# repository.                                                    #
##################################################################

cur_wd="$PWD"
bitness="$(getconf LONG_BIT)"

	# Libretro gearcoleco build
	if [[ "$var" == "gearcoleco" || "$var" == "all" ]] && [[ "$bitness" == "64" ]]; then
	 cd $cur_wd
	  if [ ! -d "Gearcoleco/" ]; then
		git clone --recursive https://github.com/drhelius/Gearcoleco.git
		if [[ $? != "0" ]]; then
		  echo " "
		  echo "There was an error while cloning the libretro git.  Is Internet active or did the git location change?  Stopping here."
		  exit 1
		 fi
		cp patches/Gearcoleco-patch* Gearcoleco/.
	  fi

	 cd Gearcoleco/
	 
	 gearcoleco_patches=$(find *.patch)
	 
	 if [[ ! -z "$gearcoleco_patches" ]]; then
	  for patching in Gearcoleco-patch*
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

	  make -C platforms/libretro/ -j$(nproc)

	  if [[ $? != "0" ]]; then
		echo " "
		echo "There was an error while building the newest lr-gearcoleco core.  Stopping here."
		exit 1
	  fi

	  strip platforms/libretro/gearcoleco_libretro.so

	  if [ ! -d "../cores64/" ]; then
		mkdir -v ../cores64
	  fi

	  cp platforms/libretro/gearcoleco_libretro.so ../cores64/.

	  gitcommit=$(git log | grep -m 1 commit | cut -c -14 | cut -c 8-)
	  echo $gitcommit > ../cores$(getconf LONG_BIT)/gearcoleco_libretro.so.commit

	  echo " "
	  echo "gearcoleco_libretro.so has been created and has been placed in the rk3326_core_builds/cores64 subfolder"
	fi
