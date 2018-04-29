#!/bin/sh
#----------------------------------------------------------------
# Shell Name：install
# Description：English install.
# Author：ChocolateMilkGod
# E-mail: daniel .. smi.sh
# Time：2018-04-27 01:30 UTC
# Version: 1.00
#----------------------------------------------------------------*/

clear

## Check The Router Hardware Model
MODEL=$(cat /proc/xiaoqiang/model)
LUAPATH="/usr/lib/lua/luci"
WEBPATH="/www/xiaoqiang/web"
VERSIONPATH="/usr/share/xiaoqiang"

MOUNTFILESPATH="/tmp/langmod/tmp"

if [ "$MODEL" == "R3P" -o "$MODEL" == "R3G" ]; then
  echo "Supported Model ($MODEL)"
else
  echo "Unsupported Model"
  exit
fi

if [ ! -f /etc/langmod/.installed ]; then
  echo -n "You sure you to continue? Ctrl-C to cancel. Any key to continue."
  read continue
else
  echo -n "Waiting"
  sleep 5 #Sometimes during the boot process we execute too early, which can cause Luci to crash, among other issues.
fi

mount -o remount,rw /

umount -lf $LUAPATH 2>/dev/null
umount -lf $WEBPATH 2>/dev/null
umount -lf $VERSIONPATH 2>/dev/null

rm -rf $MOUNTFILESPATH
mkdir -p $MOUNTFILESPATH

cp -rf $LUAPATH $MOUNTFILESPATH
cp -rf $WEBPATH $MOUNTFILESPATH
cp -rf $VERSIONPATH $MOUNTFILESPATH

mount --bind $MOUNTFILESPATH/luci $LUAPATH
mount --bind $MOUNTFILESPATH/web $WEBPATH
mount --bind $MOUNTFILESPATH/xiaoqiang $VERSIONPATH

if [ ! -f /etc/langmod/base.en.lmo ]; then
  mkdir /etc/langmod/
  touch /etc/langmod/.installed
  echo -n "Downloading English Pack"
  wget http://nocrypt.smi.sh/languages/R3P/base.en.lmo -O /etc/langmod/base.en.lmo
fi

if [ ! -f /etc/langmod/base.en.lmo ]; then
  echo -n "Download Failed. Check connection"
  exit
fi

echo "Patching Files"

ln -s /etc/langmod/base.en.lmo /usr/lib/lua/luci/i18n/base.en.lmo
uci batch <<-EOF
  set luci.languages.en=English
  set luci.main.lang=en
  commit luci
EOF

sed -i 's/romChannel == "release" and features\["system"\]\["i18n"\] == "1"/romChannel == "release"/g' /usr/lib/lua/luci/view/web/inc/sysinfo.htm
sed -i 's/romChannel == "release" and features\["system"\]\["i18n"\] == "1" and ccode ~= "US"/romChannel == "release"/g' /usr/lib/lua/luci/view/web/setting/wifi.htm

sed -i 's#stable#release#g' /usr/share/xiaoqiang/xiaoqiang_version

sed -i 's/guidetoapp/hello/g' /usr/lib/lua/luci/view/web/sysauth.htm # Setup new routers without the app.
sed -i 's/<!-- <div class="pic">/<div class="pic">/g' /usr/lib/lua/luci/view/web/sysauth.htm
sed -i 's#</div> -->#</div>#g' /usr/lib/lua/luci/view/web/sysauth.htm
sed -i 's#<!-- <div class="rtname">#<div class="rtname">#g' /usr/lib/lua/luci/view/web/sysauth.htm
sed -i 's#class="detail"#class="detail" style="display: none;"#g' /usr/lib/lua/luci/view/web/sysauth.htm
sed -i 's#class="download"#class="download" style="display: none;"#g' /usr/lib/lua/luci/view/web/sysauth.htm
sed -i 's#class="tip"#class="tip" style="display: none;"#g' /usr/lib/lua/luci/view/web/sysauth.htm
sed -i 's#<%:欢迎使用小米路由器%>#<img src="<%=resource%>/web/img/<%=lang%>/bg_login_tit.png?v=<%=ver%>" height="124">#g' /usr/lib/lua/luci/view/web/sysauth.htm

sed -i 's#2015#2018#g' /usr/lib/lua/luci/view/web/inc/footer.htm
sed -i 's#2015#2018#g' /usr/lib/lua/luci/view/web/inc/footermini.htm

luci-reload
rm -r /tmp/luci-modulecache
luci-reload

echo "Making persistant between reboots"
touch /etc/firewall.user

result=$(cat /etc/firewall.user | grep langmod | wc -l) #patch firewall.user to make persistant
if [ $result == 0 ]; then
  echo "sh /etc/langmod/install.sh &" >> /etc/firewall.user
fi

result=$(cat /etc/hosts | grep bigota | wc -l) #patch hosts as we're getting forced otas at midnight as we're not matching verified firmware versions
if [ $result == 0 ]; then
  echo "127.0.0.1 bigota.miwifi.com" >> /etc/hosts
fi


dropbear
