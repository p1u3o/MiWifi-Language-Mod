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

if [ "$MODEL" == "R3P" ]; then
  echo "Supported Model ($MODEL)"
else
  echo "Unsupported Model"
  exit
fi

if [ ! -f /etc/langmod/.installed ]; then
  echo -n "You sure you to continue? Ctrl-C to cancel. Any key to continue."
  read continue
fi



mount -o remount,rw /

# We could eventually support installing to attached storage, but we won't for now, internal has more than enough room.
if [ "$MODEL" == "R1D" -o "$MODEL" == "R2D" -o "$MODEL" == "R3D"  ];then
        MIWIFIPATH="/etc"
elif [ "$MODEL" == "R3" -o "$MODEL" == "R3P" -o "$MODEL" == "R3G" ];then
        MIWIFIPATH="/etc"
fi

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

ln -s /etc/langmod/base.en.lmo /usr/lib/lua/luci/i18n/base.en.lmo

uci batch <<-EOF
  set luci.languages.en=English
  set luci.main.lang=en
  commit luci
EOF

  echo "Patching Files"
  sed -i 's/romChannel == "release" and features\["system"\]\["i18n"\] == "1"/romChannel == "release"/g' /usr/lib/lua/luci/view/web/inc/sysinfo.htm
  sed -i 's/romChannel == "release" and features\["system"\]\["i18n"\] == "1" and ccode ~= "US"/romChannel == "release"/g' /usr/lib/lua/luci/view/web/setting/wifi.htm
  
  if [ ! -f /etc/langmod/overlay/xiaoqiang_version ]; then
     mkdir /etc/langmod/overlay
    cp -rv /usr/share/xiaoqiang/* /etc/langmod/overlay
  fi
  
  result=$(mount | grep /usr/share/xiaoqiang | wc -l) #overlay

  if [ $result == 0 ]; then
    mount --bind /etc/langmod/overlay/ /usr/share/xiaoqiang/
    sed -i 's#stable#release#g' /usr/share/xiaoqiang/xiaoqiang_version
  fi
  
  sed -i 's/guidetoapp/hello/g' /usr/lib/lua/luci/view/web/sysauth.htm
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
  echo "sh /etc/langmod/install.sh" >> /etc/firewall.user
fi

dropbear
