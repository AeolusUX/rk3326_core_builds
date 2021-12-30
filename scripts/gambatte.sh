#!/bin/bash
cur_wd="$PWD"
bitness="$(getconf LONG_BIT)"

	# Libretro gambatte build
	if [[ "$var" == "gambatte" || "$var" == "all" ]] && [[ "$bitness" == "64" ]]; then
	 cd $cur_wd
	  if [ ! -d "gambatte-libretro/" ]; then
		git clone https://github.com/libretro/gambatte-libretro.git
		if [[ $? != "0" ]]; then
		  echo " "
		  echo "There was an error while cloning the libretro git.  Is Internet active or did the git location change?  Stopping here."
		  exit 1
		 fi
		cp patches/gambatte-patch* gambatte-libretro/.
	  fi

	 cd gambatte-libretro/
	 
	 gambatte_patches=$(find *.patch)
	 
	 if [[ ! -z "$gambatte_patches" ]]; then
	  for patching in gambatte-patch*
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

	  make clean
	  make -f Makefile.libretro -j$(($(nproc) - 1))

	  if [[ $? != "0" ]]; then
		echo " "
		echo "There was an error while building the newest lr-gambatte core.  Stopping here."
		exit 1
	  fi

	  strip gambatte_libretro.so

	  if [ ! -d "../cores64/" ]; then
		mkdir -v ../cores64
	  fi

	  cp gambatte_libretro.so ../cores64/.

	  gitcommit=$(git log | grep -m 1 commit | cut -c -14 | cut -c 8-)
	  echo $gitcommit > ../cores$(getconf LONG_BIT)/gambatte_libretro.so.commit

	  echo " "
	  echo "gambatte_libretro.so has been created and has been placed in the rk3326_core_builds/cores64 subfolder"
	fi
