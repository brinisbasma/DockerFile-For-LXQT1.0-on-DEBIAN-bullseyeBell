FROM debian:bullseye
ENV DEBIAN_FRONTEND noninteractive
 
RUN apt-get update && \
    apt-get install -y dbus-x11 procps psmisc && \
    apt-get install -y mesa-utils mesa-utils-extra libxv1 kmod xz-utils && \
    apt-get install -y --no-install-recommends xdg-utils xdg-user-dirs \
                       menu-xdg mime-support desktop-file-utils

# Language/locale settings
# replace en_US by your desired locale setting, 
# for example de_DE for german.
ENV LANG en_US.UTF-8
RUN echo $LANG UTF-8 > /etc/locale.gen && \
    apt-get install -y locales && \
    update-locale --reset LANG=$LANG

# LXQT desktop V0.16 pour une base de mise à jours 
RUN apt-get install -y --no-install-recommends \
        lxqt-core qtwayland5 xfwm4 && \
    apt-get install -y --no-install-recommends \
        featherpad lxqt-about lxqt-config lxqt-qtplugin \
        pavucontrol-qt qlipper qterminal

#Prépartion de l'environnement pour la nouvelle version LXQT
#Installation de git
RUN apt-get install -y git --fix-missing 

#Check for update
RUN apt-get update

#Installation de QT
RUN apt install -y qtbase5-private-dev libqt5svg5-dev qttools5-dev libqt5x11extras5-dev libpolkit-qt5-1-dev --fix-missing  
 
# Installation de KDE components (Frameworks, KScreen)
RUN apt-get install -y libkf5guiaddons-dev libkf5idletime-dev libkf5screen-dev libkf5windowsystem-dev libkf5solid-dev --fix-missing 
    
#Installation de Miscellaneous  
RUN apt install -y bash libstatgrab-dev libudev-dev libasound2-dev libpulse-dev libsensors4-dev libconfig-dev libmuparser-dev libupower-glib-dev libpolkit-agent-1-dev libpolkit-qt5-1-dev sudo libexif-dev x11-utils libxss-dev libxcursor-dev libxcomposite-dev libxcb-composite0-dev libxcb-damage0-dev libxcb-dpms0-dev libxcb-image0-dev libxcb-screensaver0-dev libxcb-util0-dev libxkbcommon-x11-dev libdbusmenu-qt5-dev libfm-dev libmenu-cache-dev lxmenu-data gtk-update-icon-cache hicolor-icon-theme xdg-utils xdg-user-dirs oxygen-icon-theme openbox-dev libxi-dev xserver-xorg-input-libinput-dev libxcb-randr0-dev libxdamage-dev libjson-glib-dev libx11-xcb-dev libjson-glib-dev libprocps-dev libxtst-dev --fix-missing 

#Clone from GITHUB ressource de git

RUN git clone https://github.com/lxqt/lxqt.git

RUN cd lxqt \ 
&& git clone https://github.com/lxqt/lxqt-build-tools.git \
&& git clone https://github.com/lxqt/lxqt-panel.git \
 && git submodule init \ 
&& git submodule update --remote --rebase
 

#Creation du repertoire de buid ressource
RUN apt-get -y --allow-unauthenticated install libsecret-1-dev cmake gcc g++ binutils make 

RUN cd 
RUN mkdir build \  
&& echo 'Starting build of lxqt 1.0'  \
&& cd build 

#Démérage de la compilation de la nouvelle version LXQT
RUN cmake lxqt -DCMAKE_INSTALL_PREFIX=/usr -Wno-deprecated -DNOKDESUPPORT=false -DNOSECRETSUPPORT=false -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_PREFIX_PATH=lxqt
    
 
#Nettoyage des packages de developpement et des fichiers de code sources  
RUN echo 'Cleanup dev tools and source files from lxqt 1.0' \
    && cd ./. \
    && rm -rf lxqt* \
    && apt-get purge --yes --allow-downgrades --allow-change-held-packages libgcrypt20-dev qttools5-dev libsecret-1-dev qtbase5-dev cmake gcc g++ binutils make \
    && apt-get autoclean --yes \
    && apt-get autoremove --yes --allow-downgrades --allow-change-held-packages \
    && rm -rf /var/lib/apt/lists/ * \
    && apt-get update

# config lxqt 
RUN mkdir -p /etc/skel/.config/lxqt && \
    echo '[General]\n\
__userfile__=true\n\
icon_theme=Adwaita\n\
single_click_activate=false\n\
theme=ambiance\n\
tool_button_style=ToolButtonTextBesideIcon\n\
\n\
[Qt]\n\
doubleClickInterval=400\n\
font="Sans,11,-1,5,50,0,0,0,0,0"\n\
style=Fusion\n\
wheelScrollLines=3\n\
' >/etc/skel/.config/lxqt/lxqt.conf && \
    echo '[General]\n\
__userfile__=true\n\
[Environment]\n\
TERM=qterminal\n\
' >/etc/skel/.config/lxqt/session.conf

# config pcmanfm-qt
RUN mkdir -p /etc/skel/.config/pcmanfm-qt/lxqt && \
    echo '[Desktop]\n\
ShowHidden=true\n\
Wallpaper=/usr/share/lxqt/themes/ambiance/Butterfly-Kenneth-Wimer.jpg\n\
WallpaperMode=stretch\n\
' >/etc/skel/.config/pcmanfm-qt/lxqt/settings.conf

# config panel / add some launchers
RUN mkdir -p /etc/xdg/lxqt && echo '[quicklaunch]\n\
alignment=Left\n\
apps\\1\desktop=/usr/share/applications/pcmanfm-qt.desktop\n\
apps\\2\desktop=/usr/share/applications/qterminal.desktop\n\
apps\\3\desktop=/usr/share/applications/juffed.desktop\n\
apps\size=3\n\
type=quicklaunch\n\
' >> /etc/xdg/lxqt/panel.conf

RUN echo '#! /bin/bash\n\
xdpyinfo | grep -q -i COMPOSITE || echo "x11docker/lxqt: X extension COMPOSITE not found.\n\
Graphical glitches might occur.\n\
If you run with x11docker option --nxagent, please add option --composite.\n\
" >&2\n\
startlxqt\n\
' > /usr/local/bin/start && \
chmod +x /usr/local/bin/start

CMD start
   
