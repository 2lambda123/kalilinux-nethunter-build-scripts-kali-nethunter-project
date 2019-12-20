# NetHunter - Mobile Penetration Testing Platform   
# _Rootless Editions_   

###### For use on unmodified stock Android phones without voiding the warranty

![Kali NetHunter](https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project/raw/master/images/nethunter-git-logo.png)
### NetHunter Termux Edition  

[![](../images/010-NH-Rootless-Installation_Start_s.jpg)](../images/010-NH-Rootless-Installation_Start.jpg)



[![](../images/020-NH-Rootless-KeX_s.jpg)](../images/020-NH-Rootless-KeX_s.jpg)



Prerequisite:  
--------------  
Android Device  
(Stock unmodified device, no root or custom recovery required)  

  

Installation:  
--------------  
* Install nethunter-store app from https://store.nethunter.com  
* From nethunter store, install __Termux__, __NetHunter-KeX client__, and __Hacker's keyboard__  
_Note: Termux installs on all devices but on some the button "install" may not change to "installed" in the store client after installation - just ignore it.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Starting termux for the first time may seem stuck while displaying "installing" on some devices - just hit enter._  
  
* Open Termux and type:  
`termux-setup-storage`  
`pkg install wget`   
`wget -O install-nethunter-termux https://offs.ec/2MceZWr`  
`chmod +x install-nethunter-termux`  
`./install-nethunter-termux`  

Usage:  
-------  
Open Termux and type one of the following:  

| Command                 | To                                                         |
| ----------------------- | ---------------------------------------------------------- |
| `nethunter`             | start Kali NetHunter command line interface                |
| `nethunter kex passwd`  | Configure the KeX password (only needed before 1st use)    |
| `nethunter kex &`       | start Kali NetHunter Desktop Experience                    |
| `nethunter kex stop`    | stop Kali NetHunter Desktop Experience                     |

Note: The command `nethunter` can be abbreviated to `nh`.

To use KeX, start the KeX client, enter your password and click connect  
_Tip: For a better viewing experience, enter a custom resolution under "Advanced Settings" in the KeX Client_
