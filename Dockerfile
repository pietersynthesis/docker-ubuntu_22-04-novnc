################################################################################
# base system
################################################################################

FROM ubuntu:22.04 as system

# Avoid prompts for time zone
ENV DEBIAN_FRONTEND noninteractive
ENV TZ=Africa/Johannesburg
# Fix issue with libGL on Windows
ENV LIBGL_ALWAYS_INDIRECT=1

# built-in packages
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        apt-utils \
    && apt-get install -y --no-install-recommends \
        software-properties-common \
        curl \
        apache2-utils \
        supervisor \
        nginx sudo \
        net-tools \
        zenity \
        apt-utils \
        dbus-x11 \
        x11-utils \
        alsa-utils \
        mesa-utils \
        wget \
        python3-dev \
        python3-pip \
        python3-tk \
        gcc \
        make \
        cmake \
        build-essential \
        iputils-ping \
        gpg-agent \
        apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# install debs error if combine together
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        xvfb \
        x11vnc \
        vim-tiny \
        ttf-wqy-zenhei \
    && rm -rf /var/lib/apt/lists/*

# install desktop environment
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        lxde \
        gtk2-engines-murrine \
        gnome-themes-standard \
        arc-theme \
    && rm -rf /var/lib/apt/lists/*

# tini to fix subreap
ARG TINI_VERSION=v0.19.0
RUN wget https://github.com/krallin/tini/archive/v0.19.0.tar.gz \
 && tar zxf v0.19.0.tar.gz \
 && export CFLAGS="-DPR_SET_CHILD_SUBREAPER=36 -DPR_GET_CHILD_SUBREAPER=37"; cd tini-0.19.0; cmake . && make && make install \
 && cd ..; rm -r tini-0.19.0 v0.19.0.tar.gz

#Firefox with apt, not snap (which does not run in the container)
COPY mozilla-firefox_aptprefs.txt /etc/apt/preferences.d/mozilla-firefox
RUN add-apt-repository -y ppa:mozillateam/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends --allow-downgrades \
        firefox \
        fonts-lyx \
    && rm -rf /var/lib/apt/lists/*

# # Firefox with apt, not snap (which does not run in the container)
# COPY mozilla-firefox_aptprefs.txt /etc/apt/preferences.d/mozilla-firefox
# RUN add-apt-repository -y ppa:mozillateam/ppa
# RUN apt-get update && apt-get install -y --allow-downgrades firefox fonts-lyx

# Killsession app
COPY killsession/ /tmp/killsession
RUN cd /tmp/killsession; \
    gcc -o killsession killsession.c \ 
    && mv killsession /usr/local/bin \ 
    && chmod a=rx /usr/local/bin/killsession \
    && chmod a+s /usr/local/bin/killsession \ 
    && mv killsession.py /usr/local/bin/ && chmod a+x /usr/local/bin/killsession.py \
    && mkdir -p /usr/local/share/pixmaps && mv killsession.png /usr/local/share/pixmaps/ \
    && mv KillSession.desktop /usr/share/applications/ && chmod a+x /usr/share/applications/KillSession.desktop \ 
    && cd /tmp && rm -r killsession
    
# python libraries
COPY rootfs/usr/local/lib/web/backend/requirements.txt /tmp/
RUN apt-get update \
    && dpkg-query -W -f='${Package}\n' > /tmp/a.txt \
    && pip3 install -r /tmp/requirements.txt \
    && ln -s /usr/bin/python3 /usr/local/bin/python \
    && dpkg-query -W -f='${Package}\n' > /tmp/b.txt \
    && apt-get remove `diff --changed-group-format='%>' --unchanged-group-format='' /tmp/a.txt /tmp/b.txt | xargs` \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/* /tmp/a.txt /tmp/b.txt

# dev packages
RUN apt-get update \
     && apt-get install -y --no-install-recommends \
        visualvm \
        openjdk-8-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/Desktop
RUN mkdir -p /root/.local/share/applications

RUN echo '[Desktop Entry]\n \
          Type=Link\n \
          Name=VisualVM\n \
          Icon=visualvm\n \
          URL=/usr/share/applications/visualvm.desktop' > /root/Desktop/visualvm.desktop

# Install VS Code
RUN wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/vscode.gpg \
    && echo deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main | tee /etc/apt/sources.list.d/vscode.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        code \
    && rm -rf /var/lib/apt/lists/*

# Note launch parameters: --unity-launch --no-sandbox --user-dir /root, running VS Code as the root user is not recommended
RUN echo '[Desktop Entry]\n \
          Name=Visual Studio Code\n \
          Comment=Code Editing. Redefined.\n \
          GenericName=Text Editor\n \
          Exec=/usr/share/code/code --unity-launch --no-sandbox --user-dir /root %F\n \
          Icon=com.visualstudio.code\n \
          Type=Application\n \
          StartupNotify=false\n \
          StartupWMClass=Code\n \
          Categories=TextEditor;Development;IDE;\n \
          MimeType=text/plain;inode/directory;application/x-code-workspace;\n \
          Actions=new-empty-window;\n \
          Keywords=vscode;\n \
          \n \
          [Desktop Action new-empty-window]\n \
          Name=New Empty Window\n \
          Exec=/usr/share/code/code --new-window %F\n \
          Icon=com.visualstudio.code' > /root/Desktop/code.desktop

# Install Postman
RUN add-apt-repository ppa:tiagohillebrandt/postman \ 
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        postman \
    && rm -rf /var/lib/apt/lists/*

# Install IntelliJ IDEA Community
RUN wget https://download.jetbrains.com/idea/ideaIC-2022.3.1.tar.gz \
    && tar -xzf ideaIC-2022.3.1.tar.gz -C /opt \
    && rm ideaIC-2022.3.1.tar.gz \
    && echo '[Desktop Entry]\n \
          Version=1.0\n \
          Type=Application\n \
          Name=IntelliJ IDEA Community Edition\n \
          Icon=/opt/idea-IC-223.8214.52/bin/idea.svg\n \
          Exec="/opt/idea-IC-223.8214.52/bin/idea.sh" %f\n \
          Comment=Capable and Ergonomic IDE for JVM\n \
          Categories=Development;IDE;\n \
          Terminal=false\n \
          StartupWMClass=jetbrains-idea-ce\n \
          StartupNotify=true' > /root/.local/share/applications/jetbrains-idea-ce.desktop \
    && echo '[Desktop Entry]\n \
          Type=Link\n \
          Name=IntelliJ IDEA Community Edition\n \
          Icon=/opt/idea-IC-223.8214.52/bin/idea.svg\n \
          URL=/root/.local/share/applications/jetbrains-idea-ce.desktop' > /root/Desktop/jetbrains-idea-ce.desktop

# Install dbeaver:
RUN wget https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb \ 
    && dpkg -i dbeaver-ce_latest_amd64.deb \
    && rm dbeaver-ce_latest_amd64.deb \
    && echo '[Desktop Entry]\n \
          Type=Link\n \
          Name=dbeaver-ce\n \
          Icon=/usr/share/dbeaver-ce/dbeaver.png\n \
          URL=/usr/share/applications/dbeaver-ce.desktop' > /root/Desktop/DBeaver CE.desktop

# Install docker.io
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        docker.io \
    && rm -rf /var/lib/apt/lists/*


################################################################################
# builder
################################################################################
FROM ubuntu:22.04 as builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gnupg \
    && rm -rf /var/lib/apt/lists/*

# nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y --no-install-recommends \
        nodejs \
    && rm -rf /var/lib/apt/lists/*

# yarn
RUN curl -fs https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/yarnpkg_pubkey.gpg
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        yarn \
    && rm -rf /var/lib/apt/lists/*

# build frontend
COPY web /src/web
RUN cd /src/web \
    && yarn upgrade \
    && yarn \
    && yarn build
RUN sed -i 's#app/locale/#novnc/app/locale/#' /src/web/dist/static/novnc/app/ui.js

################################################################################
# merge
################################################################################
FROM system
LABEL maintainer="pieter@synthesis.co.za"

COPY --from=builder /src/web/dist/ /usr/local/lib/web/frontend/
COPY rootfs /
RUN ln -sf /usr/local/lib/web/frontend/static/websockify /usr/local/lib/web/frontend/static/novnc/utils/websockify \ 
    && chmod +x /usr/local/lib/web/frontend/static/websockify/run

EXPOSE 80
WORKDIR /root
ENV HOME=/home/ubuntu \
    SHELL=/bin/bash
HEALTHCHECK --interval=30s --timeout=5s CMD curl --fail http://127.0.0.1:6079/api/health
ENTRYPOINT ["/startup.sh"]
