PTJ-Karma
=========

Script to make wifi karma attacks much simpler

ptjkarma.sh was designed to make it very simple to create a rogue access point that mimics probed APs. 
Once the client connects to the fake AP, it will be granted a DHCP address and internet access.
This is the modular point for extensions, you can do w/e you want after this point.

-The options are set within the script itself

-Fairly well commented so it should be easy to understand

-spawns seperate xterm windows for airbase and the dhcp server

-!!!!!!THIS SCRIPT WIPES OUT PREVIOUS DHCPD CONFIGS!!!!!
