
# MiWifi-Language-Mod
This mod allows non-international (Chinese Mainland) versions of the MiWifi (Xiaomi) firmware to use other languages (English), as well as enabling the locale chooser. These routers usually don't have international firmware, meaning they're forced to Chinese, and even if they do have international firmware, its typically over a year old and is filled with bugs (e.g. R3P int firmware has channel issues). This mod isn't "perfect", there's still parts that are not translated.

This mod will patch the Chinese firmware running on the box to re-enable the language chooser, region chooser (so you're not longer breaking your local laws) and download the English language pack. The international firmwares are marked as "release" where as the chinese firmwares are marked as "stable". So we patch out the parts of Luci that check for "release".

We then install these changes to /etc/firewall.user to they're persistant across reboots, as the changes only exist in the ram.

Right now **only** the Xiaomi Router 3 Pro (**R3P**) is **supported**, R3G is next as its the only other Xiaomi Router I currently have, you're more than welcome to patch this to work on other models.

To install, make sure you're on the Developer Version of the firmware with SSH enabled. Enabling this is outside the scope of this tutorial, a quick Google will find the instructions.

    mkdir /etc/langmod; cd /etc/langmod; wget http://nocrypt.smi.sh/install.sh; sh install.sh

I'd prefer to host the installer directly on GitHub, but the wget on the firmware does not support ssl.


**Warning -** This mod creates a bind mount so it can patch the firmware to be "release" and not "stable". For some reason this can cause Dropbear not to start, however to be on the safe side this mod will start it manually anyway at each boot.
