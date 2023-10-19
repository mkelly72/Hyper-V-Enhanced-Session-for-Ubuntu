# Hyper-V-Enhanced-Session-for-Ubuntu

These scripts will enable Enhanced Sessions for Ubuntu running in Hyper-V and enable audio. I have tested it using AMD64 and ARM64 architectures for Ubuntu 22.04, 23.04, and 23.10.

There are two scripts. You will need to run "setup.sh" in your favorite bash shell Ubuntu and "Linux-Enhanced-Session.ps1" in PowerShell in Windows.

<b>The bash script will make the following changes to your Ubuntu VM:</b>
1. Ensure you are able to download source code from your apt sources. This is needed to build the audio driver.
2. Download and install updates.
3. Change your kernel to the most recent linux-azure kernel. While you can use the default kernel after installing the necessary modules, the linux-azure kernel is better tuned for Hyper-V VMs.
4. Install and configure the xrdp service. Hyper-V Enhanced Sessions uses RDP.
5. Compile and install pulseaudio. Older releases use pulseaudio by default, but newer releases do not, and the only RDP audio drivers that work are pulseaudio drivers.
6. Compile and install the xrdp pulseaudio driver. The reason we needed to compile pulseaudio is because you cannot compile the drivers without the pulseaudio build directory.

<b>The PowerShell script changes the VM transport type to HvSocket, which is necessary for Enhanced Sessions.</b>

# Instructions:
1. Download the "setup.sh" file into your Ubuntu VM. It doesn't matter where, as long as you have access to it.
2. Open your favorite bash shell and navigate to the directory in which you downloaded "setup.sh".
3. Make "setup.sh" executable. Type the following command: chmod +x setup.sh
4. Type the following command: ./setup.sh
5. Follow the directions in the prompt. You will need to supply your sudo password after running the script, but do NOT run the script as superuser.
6. You may need to reboot several times and re-run the script. This is normal, though if your VM has been updated recently that will cut down on the number of reboots.
7. After the audio driver is built and installed, the script will prompt you to shut down your VM. Don't reboot, shut it down.
8. Once the VM is shut down, download the "Linux-Enhanced-Session.ps1" script to the Windows machine running the VM.
9. The script needs to be run as an adminstrator, but the script is self-elevating. You can simply right click the script and choose "Run with PowerShell".
10. Choose "Yes" when asked if you want the script to make changes to your computer.
11. If the script fails to elevate to administrator at this point, it is likely because your user permissions do not allow it. You will have to fix this problem on your own. Google will be of more help to you than I will. You can also try to open PowerShell as admin and run the script from there (enter ".\Linux-Enhanced-Session.ps1" without the double quotes).
12. When prompted, enter the name of your VM. This is the same name listed in the Hyper-V Manager list of Virtual Machines.
13. You will see errors in red if the command fails. Likely you supplied the wrong VM name, though I have not tested this script in every scenario possible.
14. Press enter to close the window.
15. If there were no errors in the PowerShell script, you can now turn on your VM.
16. As it is booting, you should see a prompt to set your screen resolution. This means you are in an Enhanced Session.
17. You can switch between an Enhanced Session and a regular session. However, xrdp will not allow a single user to log into both xrdp and another login manager (e.g. GDM3). So always make sure you log out BEFORE switching from enhanced to regular, and vice versa.
