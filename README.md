# Autoscroll xournal++ plugin
A .lua plugin, that adds the famous "autoscroll" feature, present on firefox based browsers.

## Note

The plugin only works in the x11 linux environment, and with the flatpak version of the application. 

## Overview

The autoscroll is activated by pressing the "g" character, and pressing it again will deactivate it. The shortcut can be modified directly in the source code.

## How to install

**Step 1**
Go in the plugins directory `/home/$USER/.var/app/com.github.xournalpp.xournalpp/config/xournalpp/plugins/` and create a new `autoscroll` directory

**Step 2** 
Place the `main.lua` file inside the `autoscroll` directory.
Place the `plugin.ini` in the same directory. 

**Step 3**
Create a `/home/$USER/.var/app/com.github.xournalpp.xournalpp/config/xournalpp/icon` directory. Place the `autoscroll.svg` icon inside the `icon` folder.

Go inside the `main.lua` file, and edit the svg location of the `ICON_PATH` variable.
