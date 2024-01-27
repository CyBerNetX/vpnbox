#!/bin/bash

# script de creation d un web kiosk sur raspberry pi 3/4,
# avec ecran 7 pouces.
#
# auteur : jb masurel
# licence : gpl v3
#
############### Varriables ##################
REALPATH=$(dirname $(realpath -s $0))
app="sleep 10 && $REALPATH/$(basename $0)"

SUDO=/usr/bin/sudo

############## fonction debut ##############

function usage(){
    echo "$0 -h"
    echo " -a  execute fonction A"
    echo ""
    echo " -b  execute fonction B"
    echo ""
    echo " -c  execute fonction C"
    echo ""
    echo "Auteur : CyBerNetX"
    echo "licence GPL v3"
    exit 0
}




function cronparam(){
    case $@  
    in

        adda)
            echo "pas de paramettre add -a"
            if [[ -z $( crontab -l|grep "@reboot $app" ) ]]
            then
                echo "crontab vide: add 1er_run"
                #ADD
                #(crontab  -l ; echo "@reboot $0 -a") | crontab -
                ( crontab -l; echo "@reboot $app -a 2>&1 | tee -a /dev/tty1 /root/installer_webkiosk.log" ) | crontab -
            else
                echo "crontab plein"
            fi
        ;;
        addbdela)
        echo "first run"
        echo "first_run del 1 add 2"
        if [[ -n $( crontab -l|grep "@reboot $app -a" ) ]]
        then
            echo "crontab first_run: del 1er run"
            #DEL
            #crontab -l | grep -v "@reboot $0 -a"  | crontab -
            ( crontab -l|grep -v "@reboot $app -a" ) | crontab -
            #ADD
            #(crontab  -l ; echo "@reboot $0 -b") | crontab -
            ( crontab -l; echo "@reboot $app -b 2>&1 | tee -a /dev/tty1 /root/installer_webkiosk.log" ) | crontab -
        fi
        ;;

        addcdelb)
        echo "second run"
        echo "second_run DEL 2 ADD 3"
        if [[ -n $( crontab -l|grep "@reboot $app -b 2>&1 | tee -a /dev/tty1 /root/installer_webkiosk.log" ) ]]
        then
            echo "crontab second_run: del 2eme run"
            #DEL
            #crontab -l | grep -v "@reboot $0 -b"  | crontab -
            ( crontab -l|grep -v "@reboot $app -b" ) | crontab -
            #ADD
            #(crontab  -l ; echo "@reboot $0 -c") | crontab -
            ( crontab -l; echo "@reboot $app -c 2>&1 | tee -a /dev/tty1 /root/installer_webkiosk.log" ) | crontab -
        fi
        ;;

        delc)
        echo "third run"
        echo "third_run DEL 3 "
        if [[ -n $( crontab -l|grep "@reboot $app -c 2>&1 | tee -a /dev/tty1 /root/installer_webkiosk.log" ) ]]
        then
            echo "crontab second_run: del 3eme run"
            #DEL
            #crontab -l | grep -v "@reboot $0 -c"  | crontab -
            ( crontab -l|grep -v "@reboot $app -c" ) | crontab -
            #ADD
            #(crontab  -l ; echo "@reboot $0 -d") | crontab -
            #( crontab -l; echo "@reboot $app -d 2>&1 | tee -a /dev/tty1 /root/installer_webkiosk.log" ) | crontab -
        fi
        ;;
        

    esac
}

function fonction_A(){

    # MAJ

    $SUDO raspi-config nonint do_wifi_country FR
    $SUDO raspi-config nonint do_hostname "vpnBox"
    $SUDO apt-get update -y
    $SUDO apt-get install openvpn curl -y
    $SUDO apt-get dist-upgrade -y
    

    [[ ! -e /lib/systemd/system/kiosk.service ]] && cat <<'EOFKIOSKSRVCS' > /lib/systemd/system/kiosk.service
[Unit]
Description=Chromium Kiosk
Wants=graphical.target
After=graphical.target

[Service]
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
Type=simple
ExecStart=/bin/bash /lib/systemd/system/kiosk.sh
Restart=on-abort
User=pi
Group=pi

[Install]
WantedBy=graphical.target
EOFKIOSKSRVCS


[[ ! -e /lib/systemd/system/kiosk.sh ]] && cat <<'EOFKIOSKSH' > /lib/systemd/system/kiosk.sh
#!/bin/bash
xset s noblank
xset s off
xset -dpms

unclutter -idle 0.5 -root &

sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences

/usr/bin/chromium-browser --noerrdialogs --disable-infobars --kiosk http://admin:secret@localhost/index.php?page=dashboard_tft &

while true; do
   xdotool keydown ctrl+Tab; xdotool keyup ctrl+Tab;
   sleep 10
done
EOFKIOSKSH

}

function fonction_B(){
        
    # INSTALL RASPAP

    echo ""
    echo -e "Script 2 : Installer le hotspot WIFI"
    echo ""

    sleep 2
    #wget -q https://git.io/voEUQ -O /tmp/raspap && bash /tmp/raspap -b 1.5
    curl -sL https://install.raspap.com | bash -s -- --yes --openvpn 1 --adblock 1 -r https://github.com/RaspAP/raspap-webgui -b 1.5
}



function fonction_C(){

echo ""
echo -e "Script 3 : Installation interface graphique"
echo ""
echo ""
sleep 2
# WEBUI
echo ""
echo -e "INSTALLATION INTERFACE ECRAN GPIO"
echo ""
echo ""
sleep 2
#$SUDO /bin/cp -rf $REALPATH/html/* /var/www/html

# PERMISSION
echo ""
echo -e "INSTALLATION DES PERMISSIONS"
echo ""
echo ""
sleep 2

[[ ! -e /etc/sudoers.d/kioskh ]] && cat <<'EOFSUDOERKIOSK'| $SUDO tee /etc/sudoers.d/kiosk
www-data ALL=(ALL) NOPASSWD: /usr/sbin/openvpn
www-data ALL=(ALL) NOPASSWD: /usr/bin/killall
EOFSUDOERKIOSK


# INSTALL
echo ""
echo -e "INSTALLATION DU MODE FULLSCREEN"
echo ""
echo ""
sleep 2
$SUDO apt-get install -y xdotool unclutter sed

# INSTALL SERVICES
echo ""
echo -e "INSTALLATION DES SERVICES AU DEMARRAGE!"
echo ""
echo ""
sleep 2
$SUDO systemctl enable kiosk.service

echo ""
echo -e "MODIFICATION RESOLUTION ECRAN"
echo ""
echo ""

cat << 'EOFRPICNFIG' |$SUDO tee -a  /boot/config.txt
framebuffer_width=720
framebuffer_height=480
EOFRPICNFIG


#CONF ECRAN
echo ""
echo -e "CONFIGURATION DE L'ECRAN"
echo ""
echo ""
sleep 2
cd $REALPATH || exit
git clone https://github.com/waveshare/LCD-show.git
cd LCD-show/ || exit
#$SUDO ./LCD35-show 180

}

############## fonction fin ##############


if [ `whoami` = "root" ]; then

    if [[ -n $conffile ]]
    then
        source $conffile
    fi

 #   checkvar
    
    cronparam adda
    while getopts abch option
    do 
        case "${option}"
            in
            a)
            cronparam addbdela
            fonction_A
            
            ;;
            b)
            cronparam addcdelb
            fonction_B
            
            ;;
            c)
            cronparam delc
            fonction_C
            ;;


            h) usage ;;
	    *) usage ;exit ;;
        esac
        
    done
    
    
    echo "reboot !"
    /usr/sbin/shutdown -r 0
    
    
else
	echo "se script à besoin d'être lancer en tant que root!"
    usage
fi
