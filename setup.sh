#!/bin/bash

# check that wine is installed
if [ ! `which wine` ]; then
	echo 'Please install wine manually first: apt-get install wine'
	exit 0
fi

if [ -d fceux ]; then
	echo 'FCEUX is already installed'
else
	# download fceux
	wget 'http://heanet.dl.sourceforge.net/project/fceultra/Binaries/2.2.2/fceux-2.2.2-win32.zip'
	# extract it and remove archive
	unzip fceux-2.2.2-win32.zip -d fceux
	rm fceux-2.2.2-win32.zip
fi

# download S.M.B. rom
wget 'http://23.227.191.210/997ajxXXajs13jJKPxOa/may/120/NES%20Roms/Super%20Mario%20Bros.%20(Japan,%20USA).zip' -O SuperMarioBros.zip
unzip SuperMarioBros.zip
rm SuperMarioBros.zip
mv 'Super Mario Bros. (Japan, USA).nes' roms/SuperMarioBros.nes

# copy savestate file to fceux(s) folder(s)
if [ ! `which fceux` ]; then
	echo 'Please install fceux for your distribution (e.g. apt-get install fceux)'
	exit 0
else
	cp roms/SuperMarioBros.fc0 ~/.fceux/fcs
	cp roms/SuperMarioBros.fc0 ./fceux/fcs
fi

echo 'Do you want to run the test now? [y/N]'
read -n 1 answer
if [ $answer == 'y' ]; then
	wine fceux/fceux.exe -lua test.lua roms/SuperMarioBros.nes
fi
