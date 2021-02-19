# [xRDP for Kali Linux on WSL1/2 (Version 1.0 / 20210219)](https://github.com/DesktopECHO/xWSL)

One-line command to install a GUI on Kali Linix from the Windows Store. 

**INSTRUCTIONS:  From an elevated prompt, change to your desired install directory and type/paste the following command:**

    PowerShell -executionpolicy bypass -command "wget https://github.com/DesktopECHO/xWSL/raw/KaliWSL/xWSL.cmd -UseBasicParsing -OutFile xWSL.cmd ; .\xWSL.cmd"

You will be asked a few questions.  The installer script finds the current DPI scaling in Windows, you can set your own value if preferred:

[Kali xRDP Installer 20210219]

Enter name of Kali distro to install xRDP or hit Enter for default [kali-linux]:
Port number for xRDP traffic or hit Enter for default [3399]:
Port number for SSHd traffic or hit Enter for default [3322]:
Set a custom DPI scale, or hit Enter for Windows default [1.5]: 2
[Not recommended!] Type X to eXclude from Windows Defender:

The installer will download and install the [LxRunOffline](https://github.com/DDoSolitary/LxRunOffline) distro manager.  Reference times will vary depending on system performance and the presence of antivirus software.  A fast system with good Internet can finish in under 20 minutes. 

    [10:03:00] Git clone and update repositories (~1m15s)
    [10:03:16] Configure apt-fast Downloader (~0m15s)
    [10:03:18] Kali Linux Default (~4m45s)
   
At the end of the script you will be prompted to create a non-root user which will automatically be added to sudo'ers.

     Enter name of primary user for XFCE416: zero
     Enter password for zero: ********

     Open Windows Firewall Ports for xRDP, SSH, mDNS...
     Building RDP Connection file, Console link, Init system...
     Building Scheduled Task...
     SUCCESS: The scheduled task "XFCE416" has successfully been created.
     
           Start: Mon 12/14/2020 @ 11:14
             End: Mon 12/14/2020 @ 11:24
        Packages: 968

       - xRDP Server listening on port 13399 and SSHd on port 13322.

       - Links for GUI and Console sessions have been placed on your desktop.

       - (Re)launch init from the Task Scheduler or by running the following command:
         schtasks.exe /run /tn kali-linux
     
      kali-linux Installation Complete!  GUI will start in a few seconds...

A fullscreen XFCE session will launch using your stored credentials. 

**Configure xWSL to start at boot (like a service, no console window)**

* Right-click the task in Task Scheduler, click properties
* Click the checkbox for **Run whether user is logged on or not** and click **OK**
* Enter your Windows credentials when prompted
 
Reboot your PC when complete and the xRDP service in Kali will startup automatically with your system.

**Start/Stop Operation**

* Reboot the instance (example with default distro name of 'xWSL'): ````schtasks /run /tn kali-linux```` 
* Terminate the instance: ````wslconfig /t kali-linux````

**xWSL leverages Multicast DNS to lookup WSL2 instances**

If your computer has virtualization support you can convert it to WSL2.  xWSL is faster on WSL1, but WSL2 has additional capabilities. 

Example of conversion to WSL2 on machine name "LAPTOP":
 - Stop WSL on LAPTOP:
    ````wsl --shutdown````
 - Convert the instance to WSL2:
    ````wsl --set-version xWSL 2````
 - Restart kWSL Instance:
    ````schtasks /run /tn xWSL````
 - Edit the RDP file on your desktop to point at the WSL2 instance by adding ````-xWSL.local```` to the hostname:
    ````LAPTOP-xWSL.local:3399````

**Make it your own:**

From a security standpoint, it would be best to fork this project so you (and only you) control the packages and files in the repository.

- Sign into GitHub and fork this project
- Edit ```xWSL.cmd```.  On line 2 you will see ```SET GITORG=DesktopECHO``` - Change ```DesktopECHO``` to the name of your own repository.
- Customize the script any way you like.
- Launch the script using your repository name:
 ```PowerShell -executionpolicy bypass -command "wget https://github.com/YOUR-REPO-NAME/xWSL/raw/master/xWSL.cmd -UseBasicParsing -OutFile xWSL.cmd ; .\xWSL.cmd"```

**Quirks / Limitations / Additional Info:**

* When you log out out of a desktop session the entire xWSL instance is restarted, the equivilent of a clean-boot at every login.  Disconnected sessions will wait for your return.  
* WSL1 Doesn't work with PolicyKit. Enabled gksu for apps needing elevated rights (Synaptic, root console)
* Rebuilt xrdp 0.9.13 thanks to Sergey Dryabzhinsky @ http://packages.rusoft.ru/ppa/rusoft/xrdp/
* [Apt-fast](https://github.com/ilikenwf/apt-fast) added to improve download speed and reliability.
* Mozilla Seamonkey included as a stable browser that's kept up to date via apt.  Current versions of Chrome / Firefox do not work in WSL1.
* Installed image consumes approximately X.X GB of disk space
* XFCE uses Windows fonts (Segoe UI / Cascadia Code)
* This is a basic installation of XFCE to save bandwidth.  If you want the complete XFCE Desktop environment run `sudo apt-get install xubuntu-desktop`
* Uninstaller is located in root of xWSL folder, **'Uninstall xWSL.cmd'** - Make sure you **'Run As Administrator'** to ensure removal of the scheduled task and firewall rules

**Screenshots:**

