# NetHunter - Mobile Penetration Testing Platform   
# _Rootless Editions_         
![Kali NetHunter](https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project/raw/master/images/nethunter-git-logo.png)
## A project by Offensive Security  

### NetHunter Termux Edition  
  
Prerequisite:  
--------------  
Android Device  
Stock  
Unrooted  
Stock recovery  
  
Installation:  
--------------  
Install nethunter-store app from https://store.nethunter.com  
From nethunter store, install termux and NetHunter-KeX client  
Open termux  
termux-setup-storage  
wget https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project/raw/2020.1/nethunter-rootless/install-nethunter-termux  
chmod +x install-nethunter-termux  
./install-nethunter-termux  
  
Usage:  
-------  
Open termux and type one of the following:  
  
nethunter               # to start nethunter cli  
nethunter kex &         # to start nethunter kex  
nethunter kex stop      # to stop kex  
  
For KeX, start KeX client, enter password and click connect  
