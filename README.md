# azterisk.host Port Forwarder

Automatically host games and servers from your local machine, using UPnP to communicate with your router. No need to log into your router's admin panel.

## Features
- Presets for Counter-Strike 2, Minecraft, Palworld, Rust, and more
- Instantly forward ports with a single click
- Auto-detects your external IP

## Installation

1. Make sure you have `miniupnpc` installed:
   ```bash
   sudo pacman -S miniupnpc
   ```
2. Clone this repository to your Omarchy plugins directory:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/azterisk.host
   cp -r * ~/.config/omarchy/plugins/azterisk.host/
   ```
3. Open your Omarchy launcher and add the `azterisk.host` menu.
