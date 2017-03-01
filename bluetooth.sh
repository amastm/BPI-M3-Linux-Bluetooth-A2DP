#!/bin/bash
echo "===BPI-M3 BLUETOOTH A2DP FOR BT SPEAKER [UE ROLL]=========================="
echo "HINT: Sudo apt-get install pulseaudio* # get the PA-bluetooth-module burried somewhere in the u16.04 packages"
echo "HINT: Device pairing is unstable, u might have to pair again another time or day"
echo "HINT: U may need a newer firmware to replace /lib/firmware/ap6212/bcm43438a0.hcd in this image from 04/25/16. I've got the 38.6 kB firmware file with md5sum 2cd6d6407ed4fb718f74f9931a30b5c8"
echo "- see https://github.com/igorpecovnik/lib/tree/master/bin/firmware-overlay/ap6212"
echo "HINT: WIFI is better turned off when using bluetooth sound output (WIFI&BT same chip, frequencies & antenna)"
echo "- both on might cause glitches, interrupted sound"
echo "CREDITS: Excellent infos can also be found linked on the troubleshooting page of blueman github repo"
echo "Credits also to this German page: https://frank-mankel.de/kategorien/bananapi-m2-ultra/225-bpi-m2-ultra-bluetooth"
echo ""
if [ -z "`hciconfig -a`" ]; then
	echo "Applying firmware patch to enable BT controller..."
	ls -al /etc/firmware/ap6212/4343A0.hcd || sudo cp /lib/firmware/ap6212/bcm43438a0.hcd /etc/firmware/ap6212/4343A0.hcd
	md5sum /etc/firmware/ap6212/4343A0.hcd
	
	sudo systemctl stop bluetooth.service

	#Update firmware
	sudo sh -c "echo '0' > /sys/class/rfkill/rfkill0/state"
	sudo sh -c "echo '1' > /sys/class/rfkill/rfkill0/state"
	echo "" > /dev/ttyS1
	sudo hciattach /dev/ttyS1 bcm43xx 1500000
	sleep 10
	check=`hciconfig -a` # check, is there a bt controller device now?
	if [ -z "$check" ]; then
		echo "error: no controller found"
		exit 1
	fi
	sudo rfkill unblock 3
	sudo service bluetooth restart
	sudo hciconfig hci0 up
fi

echo "====================================================="
#Bluetoothctl connect device steps
echo "Bluetooth is ready for connection! Follow this route (avoid MATE-GUI blueman-manager: crashes in u16.04):"
echo "#bluetoothctl -a #will be started now in a separate window. There, enter:"
echo "[bluetooth]# power on"
echo "[bluetooth]# scan on"
echo "############ be patient: wait for your \"[NEW] device XX:YY:...\" to appear"
echo "[bluetooth]# remove XX:YY:... #start fresh with pairing, if paired before"
echo "[bluetooth]# trust XX:YY:... #optional"
echo "[bluetooth]# pair XX:YY:..."
echo "############ be patient: wait for \"Pairing successful\""
echo "[bluetooth]# connect XX:YY:..."
echo "############ be patient: wait for \"Connection successful\" and check \"info\""
echo "#press key and continue, watch this windows \"awaiting card...\""
echo "[UE ROLL]# info"
echo "#check info for UUID A2DP, e.g. UUID: Audio Sink                (0000110b-0000-1000-8000-00805f9b34fb)"
echo "[UE ROLL]# select-attribute 0000110b-0000-1000-8000-00805f9b34fb"
echo "########## be patient: connect some more times, until bluez card is found..."
echo "[bluetooth/UE ROLL]# connect XX:YY:..."
echo "#keep the bluetoothctl window running, just in case..."

pkill blueman #this piece of software does not work reliable in u16.04
xterm -e "bluetoothctl -a" &
disown
sleep 10
echo "====================================================="
echo "continue with your connected device? Press any key..."
read -n 1 c

#Kick pulseaudios butt to see connected device
pulseaudio --kill
sleep 3
pulseaudio --start
sleep 1
pactl unload-module module-bluetooth-discover
sleep 1
pactl load-module module-bluetooth-discover
sleep 1

index=
echo -e "awaiting bluez card...\c"
while [ -z $index ]; do 
	sleep 3
	echo -e "...\c"  
	index=`pacmd list-cards | grep bluez_card -B1 | grep index | awk '{print $2}'`
done
echo "...found bluez card #$index !"
pacmd set-card-profile $index off
sleep 1
pacmd set-card-profile $index a2dp_sink
sleep 1
echo "please go to Configuration tab and make sure, device is a2dp_sink and select it for sound output in tab Output Devices"
pavucontrol &

echo -e "wav sound check loop, press CTRL-C to leave...\c"
while true; do   
	sleep 1;   
	echo -e "...\c"   
	aplay /usr/share/sounds/alsa/Front_Center.wav >/dev/null || break
done

echo "done A2DP"
exit 0

echo -e "mp3 sound check loop, press CTRL+C to leave...\c"
#needs: sudo apt-get install vlc
while true; do
	sleep 1
	echo -e "...\c"
	#cvlc /usr/share/sounds/alsa/Front_Center.wav || break
	cvlc yourTune.mp3 || break
done; echo "done A2DP"
