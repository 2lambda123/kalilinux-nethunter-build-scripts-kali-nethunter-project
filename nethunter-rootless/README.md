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
Install nethunter-store app from https://store.nethunter.com  
From nethunter store, install termux, NetHunter-KeX client, and Hacker's keyboard  
Open termux  
`termux-setup-storage`  
`pkg install wget`   
`wget -O install-nethunter-termux https://offs.ec/2MceZWr`  
`chmod +x install-nethunter-termux`  
`./install-nethunter-termux`  

Usage:  
-------  
Open termux and type one of the following:  

| Command                 | To                                          |
| ----------------------- | ------------------------------------------- |
| `nethunter`             | start Kali NetHunter command line interface |
| `nethunter kex passwd`  | Configure the KeX password before 1st use   |
| `nethunter kex &`       | start Kali NetHunter Desktop Experience     |
| `nethunter kex stop`    | stop Kali NetHunter Desktop Experience      |

Note: The command `nethunter` can be abbreviated to `nh`.

For KeX, start KeX client, enter password and click connect  
