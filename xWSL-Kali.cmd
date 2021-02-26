@ECHO OFF & NET SESSION >NUL 2>&1 
IF %ERRORLEVEL% == 0 (ECHO Administrator check passed...) ELSE (ECHO You need to run this command with administrative rights.  Is User Account Control enabled? && pause && goto ENDSCRIPT)
COLOR 1F
SET GITORG=DesktopECHO
SET GITPRJ=xWSL
SET BRANCH=KaliWSL
SET BASE=https://github.com/%GITORG%/%GITPRJ%/raw/%BRANCH%

REM ## Enable WSL if needed
PowerShell.exe -Command "$WSL = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' ; if ($WSL.State -eq 'Disabled') {Enable-WindowsOptionalFeature -FeatureName $WSL.FeatureName -Online}"

REM ## Install Kali from AppStore if needed
PowerShell.exe -Command "wsl -d kali-linux -e 'uname' > $env:TEMP\DistroTestAlive.TMP ; $alive = Get-Content $env:TEMP\DistroTestAlive.TMP ; IF ($Alive -ne 'Linux') {Start-BitsTransfer https://aka.ms/wsl-kali-linux-new -Destination $env:TEMP\Kali.AppX ; Add-AppxPackage $env:TEMP\Kali.AppX ; Kali.exe install --root ; Kali.exe run 'wget https://http.kali.org/kali/pool/main/k/kali-archive-keyring/kali-archive-keyring_2020.2_all.deb ; dpkg -i kali-archive-keyring_2020.2_all.deb' }" >NUL 2>&1 

CLS && SET RUNSTART=%date% @ %time:~0,5%

REM ## Find system DPI setting and get installation parameters
IF NOT EXIST "%TEMP%\windpi.ps1" POWERSHELL.EXE -ExecutionPolicy Bypass -Command "wget '%BASE%/windpi.ps1' -UseBasicParsing -OutFile '%TEMP%\windpi.ps1'"
FOR /f "delims=" %%a in ('powershell -ExecutionPolicy bypass -command "%TEMP%\windpi.ps1" ') do set "WINDPI=%%a"

REM ## Acquire LxRunOffline
IF NOT EXIST "%TEMP%\LxRunOffline.exe" POWERSHELL.EXE -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; wget https://github.com/DDoSolitary/LxRunOffline/releases/download/v3.5.0/LxRunOffline-v3.5.0-msvc.zip -UseBasicParsing -OutFile '%TEMP%\LxRunOffline-v3.5.0-msvc.zip' ; Expand-Archive -Path '%TEMP%\LxRunOffline-v3.5.0-msvc.zip' -DestinationPath '%TEMP%' -Force" > NUL
MKDIR %TEMP%\Kali-xRDP >NUL 2>&1 

ECHO [Kali xRDP Installer 20210225]
ECHO:
ECHO Hit Enter to use your current display scaling in Windows
SET /p WINDPI=or set the desired value (1.0 to 3.0 in .25 increments) [%WINDPI%]: 
SET RDPPRT=3399& SET /p RDPPRT=Port number for xRDP traffic or hit Enter for default [3399]: 
SET SSHPRT=3322& SET /p SSHPRT=Port number for SSHd traffic or hit Enter for default [3322]:
FOR /f "delims=" %%a in ('PowerShell -Command 96 * "%WINDPI%" ') do set "LINDPI=%%a"
FOR /f "delims=" %%a in ('PowerShell -Command 32 * "%WINDPI%" ') do set "PANEL=%%a"
FOR /f "delims=" %%a in ('PowerShell -Command 48 * "%WINDPI%" ') do set "ICONS=%%a"
SET DEFEXL=NONO& SET /p DEFEXL=[Not recommended!] Type X to eXclude from Windows Defender: 
SET DISTROFULL=%temp%
SET DISTRO=kali-linux
SET /A SESMAN = %RDPPRT% - 50
CD %DISTROFULL%
%TEMP%\LxRunOffline.exe su -n %DISTRO% -v 0
SET GO="%DISTROFULL%\LxRunOffline.exe" r -n "%DISTRO%" -c

IF %DEFEXL%==X (POWERSHELL.EXE -Command "wget %BASE%/excludeWSL.ps1 -UseBasicParsing -OutFile '%DISTROFULL%\excludeWSL.ps1'" & START /WAIT /MIN "Add exclusions in Windows Defender" "POWERSHELL.EXE" "-ExecutionPolicy" "Bypass" "-Command" ".\excludeWSL.ps1" "%DISTROFULL%" &  DEL ".\excludeWSL.ps1")

REM ## Workaround potential DNS issues in WSL
%GO% "rm -rf /etc/resolv.conf ; echo 'nameserver 1.1.1.1' > /etc/resolv.conf ; echo 'nameserver 8.8.8.8' >> /etc/resolv.conf ; chattr +i /etc/resolv.conf" >NUL 2>&1 

REM ## Loop until we get a successful repo update
:APTRELY
IF EXIST apterr DEL apterr
START /MIN /WAIT "apt-get update" %GO% "apt-get update 2> apterr"
FOR /F %%A in ("apterr") do If %%~zA NEQ 0 GOTO APTRELY 

ECHO:
ECHO [%TIME:~0,8%] Prepare Distro (~1m00s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-get -y install git gnupg2 libc-ares2 libssh2-1 libaria2-0 aria2 --no-install-recommends ; cd /tmp ; git clone -b %BRANCH% --depth=1 https://github.com/%GITORG%/%GITPRJ%.git ; chmod +x /tmp/xWSL/dist/usr/local/bin/apt-fast ; cp -p /tmp/xWSL/dist/usr/local/bin/apt-fast /usr/local/bin" > "%TEMP%\Kali-xRDP\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Prepare Distro.log" 2>&1
 
ECHO [%TIME:~0,8%] Install xRDP and Kali-Linux-Core packages (~3m00s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install /tmp/xWSL/deb/xrdp_0.9.13.1-1kali_amd64.deb /tmp/xWSL/deb/gksu_2.1.0_amd64.deb /tmp/xWSL/deb/libgksu2-0_2.1.0_amd64.deb /tmp/xWSL/deb/libgnome-keyring0_3.12.0-1+b2_amd64.deb /tmp/xWSL/deb/libgnome-keyring-common_3.12.0-1_all.deb /tmp/xWSL/deb/multiarch-support_2.27-3ubuntu1_amd64.deb /tmp/xWSL/deb/wslu_3.2.1-0kali1_amd64.deb sysv-rc fonts-cascadia-code compton-conf picom libxcb-damage0 xorgxrdp x11-apps x11-session-utils x11-xserver-utils dialog distro-info-data dumb-init inetutils-syslogd xdg-utils avahi-daemon libnss-mdns binutils putty unzip zip unar unzip dbus-x11 samba-common-bin lhasa arj unace liblhasa0 apt-config-icons apt-config-icons-hidpi apt-config-icons-large apt-config-icons-large-hidpi libgtkd-3-0 libvte-2.91-0 libvte-2.91-common libvted-3-0 tilix tilix-common libdbus-glib-1-2 xvfb xbase-clients python3-psutil kali-linux-core synaptic --no-install-recommends"  > "%TEMP%\Kali-xRDP\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Install xRDP and Kali-Linux-Core packages.log" 2>&1

ECHO [%TIME:~0,8%] Kali-Desktop-XFCE (~5m00s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install kali-desktop-xfce ; apt -y purge pcscd blueman bluez pulseaudio-module-bluetooth firefox-esr gir1.2-ayatanaappindicator3-0.1 gir1.2-nm-1.0 libccid libsbc1" > "%TEMP%\Kali-xRDP\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Kali-Desktop-XFCE.log" 2>&1

REM ## Additional items to install can go here...
ECHO [%TIME:~0,8%] Additional Components (~1m00s)
%GO% "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2667CA5C ; echo 'deb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main' > /etc/apt/sources.list.d/mozilla.list ; apt-get update" >NUL 2>&1 
%GO% "wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb ; apt-get -y install seamonkey-mozilla-build ./chrome-remote-desktop_current_amd64.deb /tmp/xWSL/deb/zenmap_7.80+dfsg1-1build1_all.deb /tmp/xWSL/deb/python-gtk2_2.24.0-5.1+b1_amd64.deb /tmp/xWSL/deb/python-gobject-2_2.28.6-13+b1_amd64.deb /tmp/xWSL/deb/python-numpy_1.16.2-1_amd64.deb /tmp/xWSL/deb/python-cairo_1.16.2-1+b1_amd64.deb /tmp/xWSL/deb/libffi6_3.2.1-9_amd64.deb" > "%TEMP%\Kali-xRDP\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Additional Components.log" 2>&1

%GO% "update-alternatives --set x-terminal-emulator /usr/bin/tilix.wrapper ; update-alternatives --install /usr/bin/www-browser www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/seamonkey 100" > nul 2>&1
%GO% "mv /usr/bin/pkexec /usr/bin/pkexec.orig ; echo gksudo -k -S -g \$1 > /usr/bin/pkexec ; chmod 755 /usr/bin/pkexec"
%GO% "which schtasks.exe" > "%TEMP%\SCHT.tmp" & set /p SCHT=<"%TEMP%\SCHT.tmp"
%GO% "sed -i 's#SCHT#%SCHT%#g' /tmp/xWSL/dist/usr/local/bin/restartwsl ; sed -i 's#DISTRO#%DISTRO%#g' /tmp/xWSL/dist/usr/local/bin/restartwsl"

IF %LINDPI% GEQ 288 ( %GO% "sed -i 's/HISCALE/3/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ; echo export QT_SCALE_FACTOR=3 >> /tmp/xWSL/dist/etc/profile.d/xWSL.sh ; echo export GDK_SCALE=3 >> /tmp/xWSL/dist/etc/profile.d/xWSL.sh" )
IF %LINDPI% GEQ 192 ( %GO% "sed -i 's/HISCALE/2/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ; echo export QT_SCALE_FACTOR=2 >> /tmp/xWSL/dist/etc/profile.d/xWSL.sh ; echo export GDK_SCALE=2 >> /tmp/xWSL/dist/etc/profile.d/xWSL.sh" )
IF %LINDPI% GEQ 192 ( %GO% "sed -i 's/Kali-Dark-HiDPI/Kali-Dark-xHiDPI/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml ; sed -i 's/QQQ/96/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ; sed -i 's/III/48/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml ; sed -i 's/PPP/32/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" )
IF %LINDPI% LSS 192 ( %GO% "sed -i 's/HISCALE/1/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ; sed -i 's/QQQ/%LINDPI%/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ; sed -i 's/III/%ICONS%/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml ; sed -i 's/PPP/%PANEL%/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" )
IF %LINDPI% LSS 120 ( %GO% "sed -i 's/Kali-Dark-HiDPI/Kali-Dark/g' /tmp/xWSL/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" )

%GO% "sed -i 's/ListenPort=3350/ListenPort=%SESMAN%/g' /etc/xrdp/sesman.ini"
%GO% "sed -i 's/thinclient_drives/.xWSL/g' /etc/xrdp/sesman.ini"
%GO% "sed -i 's/port=3389/port=%RDPPRT%/g' /tmp/xWSL/dist/etc/xrdp/xrdp.ini ; sed -i 's/\\h/%DISTRO%/g' /tmp/xWSL/dist/etc/skel/.bashrc"
%GO% "sed -i 's/#Port 22/Port %SSHPRT%/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/WSLINSTANCENAME/%DISTRO%/g' /tmp/xWSL/dist/usr/local/bin/initwsl"
%GO% "sed -i 's/#enable-dbus=yes/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf ; sed -i 's/#host-name=foo/host-name=%COMPUTERNAME%-%DISTRO%/g' /etc/avahi/avahi-daemon.conf ; sed -i 's/use-ipv4=yes/use-ipv4=no/g' /etc/avahi/avahi-daemon.conf"
%GO% "cp /mnt/c/Windows/Fonts/*.ttf /usr/share/fonts/truetype ; ssh-keygen -A ; adduser xrdp ssl-cert" > NUL
%GO% "find /tmp/xWSL -type d -exec chmod 755 {} \;"
%GO% "find /tmp/xWSL -type f -exec chmod 644 {} \;"
%GO% "chmod 755 /tmp/xWSL/dist/etc/profile.d/xWSL.sh /tmp/xWSL/dist/etc/xrdp/startwm.sh /tmp/xWSL/dist/usr/bin/pm-is-supported /tmp/xWSL/dist/usr/local/bin/restartwsl /tmp/xWSL/dist/usr/local/bin/initwsl ; chmod -R 7700 /tmp/xWSL/dist/etc/skel/.local"
%GO% "rm /usr/lib/systemd/system/dbus-org.freedesktop.login1.service /usr/share/dbus-1/system-services/org.freedesktop.login1.service /usr/share/polkit-1/actions/org.freedesktop.login1.policy ; rm /usr/share/dbus-1/services/org.freedesktop.systemd1.service /usr/share/dbus-1/system-services/org.freedesktop.systemd1.service /usr/share/dbus-1/system.d/org.freedesktop.systemd1.conf /usr/share/polkit-1/actions/org.freedesktop.systemd1.policy /usr/share/applications/gksu.desktop" > NUL 2>&1 
%GO% "cp -Rp /tmp/xWSL/dist/* / ; cp -Rp /tmp/xWSL/dist/etc/skel/.* /root ; update-rc.d -f xrdp enable S 2 3 4 5 ; update-rc.d -f inetutils-syslogd enable S 2 3 4 5 ; update-rc.d -f ssh enable S 2 3 4 5 ; update-rc.d -f avahi-daemon enable S 2 3 4 5 ; cd /tmp" >NUL 2>&1 

SET RUNEND=%date% @ %time:~0,5%
CD %DISTROFULL% 
ECHO:
SET /p XU=Create a NEW user in Kali for xRDP GUI login. Enter username: 
POWERSHELL -Command $prd = read-host "Enter password for %XU%" -AsSecureString ; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($prd) ; [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) > .tmp & set /p PWO=<.tmp
%GO% "useradd -m -p nulltemp -s /bin/bash -u 1001 %XU%"
%GO% "(echo '%XU%:%PWO%') | chpasswd"
%GO% "echo '%XU% ALL=(ALL:ALL) ALL' >> /etc/sudoers"
%GO% "sed -i 's/PLACEHOLDER/%XU%/g' /tmp/xWSL/xWSL.rdp"
%GO% "sed -i 's/COMPY/LocalHost/g' /tmp/xWSL/xWSL.rdp"
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
NETSH AdvFirewall Firewall add rule name="%DISTRO% Avahi Daemon" dir=in action=allow protocol=UDP localport=5353,53791 > NUL
START /MIN "%DISTRO% Init" WSL ~ -u root -d %DISTRO% -e initwsl 2
ECHO Building RDP Connection file, Init system...
ECHO @START /MIN "%DISTRO%" WSLCONFIG.EXE /t %DISTRO%                  >  "%LOCALAPPDATA%\Kali-xRDP.cmd"
ECHO @Powershell.exe -Command "Start-Sleep 3"                          >> "%LOCALAPPDATA%\Kali-xRDP.cmd"
ECHO @START /MIN "%DISTRO%" WSL.EXE ~ -u root -d %DISTRO% -e initwsl 2 >> "%LOCALAPPDATA%\Kali-xRDP.cmd"
POWERSHELL -Command "Copy-Item '%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp' ([Environment]::GetFolderPath('Desktop'))"
ECHO Building Scheduled Task...
%GO% "cp /tmp/xWSL/xWSL.xml ."
POWERSHELL -C "$WAI = (whoami)                       ; (Get-Content .\xWSL.xml).replace('AAAA', $WAI) | Set-Content .\xWSL.xml"
POWERSHELL -C "$WAC = '%LOCALAPPDATA%\Kali-xRDP.cmd' ; (Get-Content .\xWSL.xml).replace('QQQQ', $WAC) | Set-Content .\xWSL.xml"
SCHTASKS /Create /TN:%DISTRO% /XML ./xWSL.xml /F
PING -n 6 LOCALHOST > NUL 
ECHO:
ECHO:      Start: %RUNSTART%
ECHO:        End: %RUNEND%
%GO%  "echo -ne '   Packages:'\   ; dpkg-query -l | grep "^ii" | wc -l "
ECHO: 
ECHO:  - xRDP Server listening on port %RDPPRT% and SSHd on port %SSHPRT%.
ECHO: 
ECHO:  - Link for GUI session has been placed on your desktop.
ECHO: 
ECHO:  - (Re)launch init from the Task Scheduler or by running the following command: 
ECHO:    schtasks.exe /run /tn %DISTRO%
ECHO: 
ECHO: Installaion of xRDP GUI on "%DISTRO%" complete, graphical login will start in a few seconds...  
%TEMP%\LxRunOffline.exe set-uid -n "%DISTRO%" -v 1001
PING -n 6 LOCALHOST > NUL 
START "Remote Desktop Connection" "MSTSC.EXE" "/V" "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp"
CD ..
ECHO: 
:ENDSCRIPT
