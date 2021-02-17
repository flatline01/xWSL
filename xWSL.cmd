@ECHO OFF & NET SESSION >NUL 2>&1 
IF %ERRORLEVEL% == 0 (ECHO Administrator check passed...) ELSE (ECHO You need to run this command with administrative rights.  Is User Account Control enabled? && pause && goto ENDSCRIPT)
COLOR 1F
SET GITORG=DesktopECHO
SET GITPRJ=xWSL
SET BRANCH=KaliWSL
SET BASE=https://github.com/%GITORG%/%GITPRJ%/raw/%BRANCH%

REM ## Find system DPI setting and get installation parameters
IF NOT EXIST "%TEMP%\windpi.ps1" POWERSHELL.EXE -ExecutionPolicy Bypass -Command "wget '%BASE%/windpi.ps1' -UseBasicParsing -OutFile '%TEMP%\windpi.ps1'"
FOR /f "delims=" %%a in ('powershell -ExecutionPolicy bypass -command "%TEMP%\windpi.ps1" ') do set "WINDPI=%%a"
:DI
CLS && SET RUNSTART=%date% @ %time:~0,5%

IF NOT EXIST "%TEMP%\LxRunOffline.exe" POWERSHELL.EXE -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; wget https://github.com/DDoSolitary/LxRunOffline/releases/download/v3.5.0/LxRunOffline-v3.5.0-msvc.zip -UseBasicParsing -OutFile '%TEMP%\LxRunOffline-v3.5.0-msvc.zip' ; Expand-Archive -Path '%TEMP%\LxRunOffline-v3.5.0-msvc.zip' -DestinationPath '%TEMP%' -Force" > NUL

ECHO [xWSL Installer 20201229]
ECHO:
ECHO Enter name of Kali distro or hit Enter to use default. 
SET DISTRO=kali-linux& SET /p DISTRO=Keep this name simple, no space or underscore characters [kali-linux]: 
SET RDPPRT=3399& SET /p RDPPRT=Port number for xRDP traffic or hit Enter to use default [3399]: 
SET SSHPRT=3322& SET /p SSHPRT=Port number for SSHd traffic or hit Enter to use default [3322]: 
                 SET /p WINDPI=Set a custom DPI scale, or hit Enter for Windows default [%WINDPI%]: 
FOR /f "delims=" %%a in ('PowerShell -Command "%WINDPI% * 96" ') do set "LINDPI=%%a"
FOR /f "delims=" %%a in ('PowerShell -Command 36 * "%WINDPI%" ') do set "PANEL=%%a"
SET DEFEXL=NONO& SET /p DEFEXL=[Not recommended!] Type X to eXclude from Windows Defender: 
SET DISTROFULL=%temp%
CD %DISTROFULL%
%TEMP%\LxRunOffline.exe su -n %DISTRO% -v 0
SET GO="%DISTROFULL%\LxRunOffline.exe" r -n "%DISTRO%" -c

IF %DEFEXL%==X (POWERSHELL.EXE -Command "wget %BASE%/excludeWSL.ps1 -UseBasicParsing -OutFile '%DISTROFULL%\excludeWSL.ps1'" & START /WAIT /MIN "Add exclusions in Windows Defender" "POWERSHELL.EXE" "-ExecutionPolicy" "Bypass" "-Command" ".\excludeWSL.ps1" "%DISTROFULL%" &  DEL ".\excludeWSL.ps1")

ECHO:
(FOR /F "usebackq delims=" %%v IN (`PowerShell -Command "whoami"`) DO set "WAI=%%v") & ICACLS "%DISTROFULL%" /grant "%WAI%":(CI)(OI)F > NUL
(COPY /Y "%TEMP%\LxRunOffline.exe" "%DISTROFULL%" > NUL ) & "%DISTROFULL%\LxRunOffline.exe" sd -n "%DISTRO%"

%GO% "echo 'nameserver 1.1.1.1' > /etc/resolv.conf"
%GO% "apt-get update ; wget -q http://mirrors.kernel.org/ubuntu/pool/main/n/nettle/libnettle7_3.5.1+really3.5.1-2_amd64.deb ; apt-get -qq install ./libnettle7_3.5.1+really3.5.1-2_amd64.deb git gnupg2 --no-install-recommends" >NUL

%GO% "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2667CA5C ; echo 'deb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main' > /etc/apt/sources.list.d/mozilla.list"  > "%TEMP%\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Mozilla Keys.log" 2>&1

:APTRELY
START /MIN /WAIT "apt-get update" %GO% "apt-get update 2> /tmp/apterr"
FOR /F %%A in ("%DISTROFULL%\rootfs\tmp\apterr") do If %%~zA NEQ 0 GOTO APTRELY 

REM -- OPENRC  %GO% "for file in /etc/rc0.d/K*; do s=`basename $(readlink "$file")` ; /etc/init.d/$s stop; done ; touch /run/openrc/softlevel"

ECHO [%TIME:~0,8%] Git clone and update repositories (~1m15s)
%GO% "cd /tmp ; git clone -b %BRANCH% --depth=1 https://github.com/%GITORG%/%GITPRJ%.git ; rm -rf /etc/apt/apt.conf.d/20snapd.conf /etc/rc2.d/S01whoopsie /etc/init.d/console-setup.sh"  > "%TEMP%\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Git Clone.log" 2>&1

:APTRELY
START /MIN /WAIT "apt-get update" %GO% "apt-get update 2> /tmp/apterr"
FOR /F %%A in ("%DISTROFULL%\rootfs\tmp\apterr") do If %%~zA NEQ 0 GOTO APTRELY 

ECHO [%TIME:~0,8%] Remove un-needed packages (~1m00s)
%GO% "apt-get -qq purge apparmor apport bolt cloud-init cloud-initramfs-dyn-netconf cryptsetup cryptsetup-initramfs dmeventd fwupd initramfs-tools initramfs-tools-core irqbalance isc-dhcp-client klibc-utils kpartx libaio1 libarchive13 libdevmapper-event1.02.1 libefiboot1 libefivar1 libestr0 libfastjson4 libfwupd2 libfwupdplugin1 libgcab-1.0-0 libgpgme11 libgudev-1.0-0 libgusb2 libisc-export1105 libisns0 libjson-glib-1.0-0 libjson-glib-1.0-common libklibc liblvm2cmd2.03 libmspack0 libnuma1 libsgutils2-2 libsmbios-c2 libtss2-esys0 liburcu6 libxmlb1 libxmlsec1 libxmlsec1-openssl libxslt1.1 linux-base lvm2 lz4 mdadm multipath-tools open-iscsi open-vm-tools plymouth popularity-contest sbsigntool secureboot-db sg3-utils sg3-utils-udev snapd squashfs-tools thin-provisioning-tools tpm-udev zerofree ; apt-get -qq autoremove --purge"  > "%TEMP%\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Purge.log" 2>&1

ECHO [%TIME:~0,8%] Configure apt-fast Downloader (~0m15s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-get -y install /tmp/xWSL/deb/aria2_1.35.0-1build1_amd64.deb /tmp/xWSL/deb/libaria2-0_1.35.0-1build1_amd64.deb /tmp/xWSL/deb/libssh2-1_1.8.0-2.1build1_amd64.deb /tmp/xWSL/deb/libc-ares2_1.15.0-1build1_amd64.deb --no-install-recommends ; chmod +x /tmp/xWSL/dist/usr/local/bin/apt-fast ; cp -p /tmp/xWSL/dist/usr/local/bin/apt-fast /usr/local/bin"  > "%TEMP%\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% AptFast.log" 2>&1

ECHO [%TIME:~0,8%] Components (~4m45s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install /tmp/xWSL/deb/gksu_2.1.0_amd64.deb /tmp/xWSL/deb/libgksu2-0_2.1.0_amd64.deb /tmp/xWSL/deb/libgnome-keyring0_3.12.0-1+b2_amd64.deb /tmp/xWSL/deb/libgnome-keyring-common_3.12.0-1_all.deb /tmp/xWSL/deb/multiarch-support_2.27-3ubuntu1_amd64.deb /tmp/xWSL/deb/libfdk-aac1_0.1.6-1_amd64.deb fonts-cascadia-code xrdp xorgxrdp x11-apps x11-session-utils x11-xserver-utils dialog distro-info-data dumb-init inetutils-syslogd xdg-utils avahi-daemon libnss-mdns binutils putty unzip zip unar unzip dbus-x11 samba-common-bin base-files packagekit packagekit-tools lhasa arj unace liblhasa0 apt-config-icons apt-config-icons-hidpi apt-config-icons-large apt-config-icons-large-hidpi libgtkd-3-0 libvte-2.91-0 libvte-2.91-common libvted-3-0 tilix tilix-common libdbus-glib-1-2 xvfb xbase-clients python3-psutil --no-install-recommends"  > "%TEMP%\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Components.log" 2>&1

ECHO [%TIME:~0,8%] XFCE (~2m00s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install xfce4 xfce4-appfinder xfce4-notifyd xfce4-terminal xfce4-whiskermenu-plugin libxfce4ui-utils libwebrtc-audio-processing1 pulseaudio xfce4-pulseaudio-plugin pavucontrol xfwm4 xfce4-panel xfce4-session xfce4-settings thunar thunar-volman thunar-archive-plugin xfdesktop4 xfce4-screenshooter libsmbclient gigolo gvfs-fuse gvfs-backends gvfs-bin mousepad evince xarchiver lhasa lrzip lzip lzop ncompress zip unzip dmz-cursor-theme adapta-gtk-theme gconf-defaults-service xfce4-taskmanager hardinfo synaptic compton compton-conf libconfig9 qt5-gtk2-platformtheme libtumbler-1-0 tumbler tumbler-common tumbler-plugins-extra --no-install-recommends" > "%TEMP%\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% XFCE.log" 2>&1

ECHO [%TIME:~0,8%] Install Mozilla Seamonkey and media playback (~1m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install seamonkey-mozilla-build vlc vlc-bin vlc-l10n vlc-plugin-notify vlc-plugin-qt vlc-plugin-samba vlc-plugin-skins2 vlc-plugin-video-splitter vlc-plugin-visualization --no-install-recommends ; update-alternatives --install /usr/bin/www-browser www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/seamonkey 100 ; cd /tmp/xWSL/deb ; wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb ; dpkg -i /tmp/xWSL/deb/chrome-remote-desktop_current_amd64.deb" > "%TEMP%\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Install Mozilla Seamonkey and media playback.log" 2>&1

ECHO [%TIME:~0,8%] Kali Packages (~10m30s)
%GO% "cd /tmp ; apt-fast -y install kali-desktop-core kali-debtags kali-desktop-xfce kali-grant-root kali-menu kali-themes kali-themes-common kali-wallpapers-2020.4" > "%TEMP%\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Kali Packages.log" 2>&1
REM  kali-linux-default 
REM ## Additional items to install can go here...
REM ## %GO% "cd /tmp ; wget https://files.multimc.org/downloads/multimc_1.4-1.deb"
REM ## %GO% "apt-get -y install supertuxkart /tmp/multimc_1.4-1.deb"

ECHO [%TIME:~0,8%] Post-install clean-up (~0m45s)

%GO% "apt-get -y purge bluez bluetooth xfce4-power-manager xfce4-power-manager-plugins xfce4-power-manager-data mesa-vulkan-drivers libxslt1.1 gnustep-base-runtime libgnustep-base1.26 gnustep-base-common gnustep-common libobjc4 powermgmt-base unar ; apt-get -y clean" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Post-install clean-up.log"

SET /A SESMAN = %RDPPRT% - 50
%GO% "which schtasks.exe" > "%TEMP%\SCHT.tmp" & set /p SCHT=<"%TEMP%\SCHT.tmp"
%GO% "mv /usr/bin/pkexec /usr/bin/pkexec.orig ; echo gksudo -k -S -g \$1 > /usr/bin/pkexec ; chmod 755 /usr/bin/pkexec"
%GO% "sed -i 's#SCHT#%SCHT%#g' /tmp/xWSL/dist/usr/local/bin/restartwsl ; sed -i 's#DISTRO#%DISTRO%#g' /tmp/xWSL/dist/usr/local/bin/restartwsl"
IF %LINDPI% GEQ 288 ( %GO% "sed -i 's/HISCALE/3/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" )
IF %LINDPI% GEQ 192 ( %GO% "sed -i 's/HISCALE/2/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" )
IF %LINDPI% GEQ 192 ( %GO% "sed -i 's/Default-hdpi/Default-xhdpi/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" )
IF %LINDPI% GEQ 192 ( %GO% "sed -i 's/16/32/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" )
IF %LINDPI% GEQ 192 ( %GO% "sed -i 's/QQQ/96/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" )
IF %LINDPI% LSS 192 ( %GO% "sed -i 's/QQQ/%LINDPI%/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" )
IF %LINDPI% LSS 192 ( %GO% "sed -i 's/HISCALE/1/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" )
IF %LINDPI% LSS 120 ( %GO% "sed -i 's/Default-hdpi/Default/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" )

%GO% "sed -i 's/ListenPort=3350/ListenPort=%SESMAN%/g' /etc/xrdp/sesman.ini"
%GO% "sed -i 's/thinclient_drives/.xWSL/g' /etc/xrdp/sesman.ini"
%GO% "sed -i 's/port=3389/port=%RDPPRT%/g' /tmp/xWSL/dist/etc/xrdp/xrdp.ini ; sed -i 's/\\h/%DISTRO%/g' /tmp/xWSL/dist/etc/skel/.bashrc"
%GO% "sed -i 's/#Port 22/Port %SSHPRT%/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/WSLINSTANCENAME/%DISTRO%/g' /tmp/xWSL/dist/usr/local/bin/initwsl"
%GO% "sed -i 's/#enable-dbus=yes/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf ; sed -i 's/#host-name=foo/host-name=%COMPUTERNAME%-%DISTRO%/g' /etc/avahi/avahi-daemon.conf ; sed -i 's/use-ipv4=yes/use-ipv4=no/g' /etc/avahi/avahi-daemon.conf"
%GO% "cp /mnt/c/Windows/Fonts/*.ttf /usr/share/fonts/truetype ; ssh-keygen -A ; adduser xrdp ssl-cert" > NUL
%GO% "chmod 644 /tmp/xWSL/dist/etc/wsl.conf ; chmod 644 /tmp/xWSL/dist/var/lib/xrdp-pulseaudio-installer/*.so"
%GO% "chmod 755 /tmp/xWSL/dist/usr/local/bin/restartwsl ; chmod 755 /tmp/xWSL/dist/usr/local/bin/initwsl ; chmod -R 700 /tmp/xWSL/dist/etc/skel/.config ; chmod -R 7700 /tmp/xWSL/dist/etc/skel/.local ; chmod 700 /tmp/xWSL/dist/etc/skel/.mozilla"
%GO% "chmod 755 /tmp/xWSL/dist/etc/profile.d/xWSL.sh ; chmod +x /tmp/xWSL/dist/etc/profile.d/xWSL.sh ; chmod 755 /tmp/xWSL/dist/etc/xrdp/startwm.sh ; chmod +x /tmp/xWSL/dist/etc/xrdp/startwm.sh"
%GO% "rm /usr/lib/systemd/system/dbus-org.freedesktop.login1.service /usr/share/dbus-1/system-services/org.freedesktop.login1.service /usr/share/polkit-1/actions/org.freedesktop.login1.policy"
%GO% "rm /usr/share/dbus-1/services/org.freedesktop.systemd1.service /usr/share/dbus-1/system-services/org.freedesktop.systemd1.service /usr/share/dbus-1/system.d/org.freedesktop.systemd1.conf /usr/share/polkit-1/actions/org.freedesktop.systemd1.policy /usr/share/applications/gksu.desktop"
%GO% "cp -Rp /tmp/xWSL/dist/* / ; cd /root   ; cp -Rp /tmp/xWSL/dist/etc/skel/* . "
%GO% "cp -Rp /tmp/xWSL/dist/* / ; cd /home/* ; cp -Rp /tmp/xWSL/dist/etc/skel/* . ; chown -R 1000:1000 ."

SET RUNEND=%date% @ %time:~0,5%
CD %DISTROFULL% 
ECHO:
SET /p XU=Enter name of primary user for %DISTRO%: 
POWERSHELL -Command $prd = read-host "Enter password for %XU%" -AsSecureString ; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($prd) ; [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) > .tmp & set /p PWO=<.tmp
%GO% "useradd -m -p nulltemp -s /bin/bash %XU%"
%GO% "(echo '%XU%:%PWO%') | chpasswd"
%GO% "echo '%XU% ALL=(ALL:ALL) ALL' >> /etc/sudoers"
%GO% "sed -i 's/PLACEHOLDER/%XU%/g' /tmp/xWSL/xWSL.rdp"
%GO% "sed -i 's/COMPY/%COMPUTERNAME%/g' /tmp/xWSL/xWSL.rdp"
%GO% "sed -i 's/RDPPRT/%RDPPRT%/g' /tmp/xWSL/xWSL.rdp"
%GO% "cp /tmp/xWSL/xWSL.rdp ./xWSL._"
ECHO $prd = Get-Content .tmp > .tmp.ps1
ECHO ($prd ^| ConvertTo-SecureString -AsPlainText -Force) ^| ConvertFrom-SecureString ^| Out-File .tmp  >> .tmp.ps1
POWERSHELL -ExecutionPolicy Bypass -Command ./.tmp.ps1
TYPE .tmp>.tmpsec.txt
COPY /y /b xWSL._+.tmpsec.txt "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp" > NUL
DEL /Q  xWSL._ .tmp*.* > NUL
ECHO:
ECHO Open Windows Firewall Ports for xRDP, SSH, mDNS...
NETSH AdvFirewall Firewall add rule name="%DISTRO% xRDP" dir=in action=allow protocol=TCP localport=%RDPPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Secure Shell" dir=in action=allow protocol=TCP localport=%SSHPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Avahi Multicast DNS" dir=in action=allow program="%DISTROFULL%\rootfs\usr\sbin\avahi-daemon" enable=yes > NUL
START /MIN "%DISTRO% Init" WSL ~ -u root -d %DISTRO% -e initwsl 2
ECHO Building RDP Connection file, Console link, Init system...
ECHO @START /MIN "%DISTRO%" WSLCONFIG.EXE /t %DISTRO%                  >  "%DISTROFULL%\Init.cmd"
ECHO @Powershell.exe -Command "Start-Sleep 3"                          >> "%DISTROFULL%\Init.cmd"
ECHO @START /MIN "%DISTRO%" WSL.EXE ~ -u root -d %DISTRO% -e initwsl 2 >> "%DISTROFULL%\Init.cmd"
ECHO @WSL ~ -u %XU% -d %DISTRO% > "%DISTROFULL%\%DISTRO% (%XU%) Console.cmd"
POWERSHELL -Command "Copy-Item '%DISTROFULL%\%DISTRO% (%XU%) Console.cmd' ([Environment]::GetFolderPath('Desktop'))"
POWERSHELL -Command "Copy-Item '%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp' ([Environment]::GetFolderPath('Desktop'))"
ECHO Building Scheduled Task...
POWERSHELL -C "$WAI = (whoami) ; (Get-Content .\rootfs\tmp\xWSL\xWSL.xml).replace('AAAA', $WAI) | Set-Content .\rootfs\tmp\xWSL\xWSL.xml"
POWERSHELL -C "$WAC = (pwd)    ; (Get-Content .\rootfs\tmp\xWSL\xWSL.xml).replace('QQQQ', $WAC) | Set-Content .\rootfs\tmp\xWSL\xWSL.xml"
SCHTASKS /Create /TN:%DISTRO% /XML .\rootfs\tmp\xWSL\xWSL.xml /F
ECHO:
ECHO:      Start: %RUNSTART%
ECHO:        End: %RUNEND%
%GO%  "echo -ne '   Packages:'\   ; dpkg-query -l | grep "^ii" | wc -l "
ECHO: 
ECHO:  - xRDP Server listening on port %RDPPRT% and SSHd on port %SSHPRT%.
ECHO: 
ECHO:  - Links for GUI and Console sessions have been placed on your desktop.
ECHO: 
ECHO:  - (Re)launch init from the Task Scheduler or by running the following command: 
ECHO:    schtasks /run /tn %DISTRO%
ECHO: 
ECHO: %DISTRO% Installation Complete!  GUI will start in a few seconds...  
PING -n 6 LOCALHOST > NUL 
START "Remote Desktop Connection" "MSTSC.EXE" "/V" "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp"
CD ..
ECHO: 
:ENDSCRIPT
