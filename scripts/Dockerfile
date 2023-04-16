FROM ubuntu:20.04

MAINTAINER Jakob Bornecrantz <jakob@collabora.com>


# Update
# Special case tzdata (needed for SDL)
# Minumal build deps
# LLVM compiler
# Deps to for LOVR (unsure about SDL)
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install wget zip git git-lfs cmake ninja-build && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install llvm-12 clang-12 lld-12 && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install libsdl2-dev libvulkan-dev libxcb-glx0-dev && \
    echo "Done"

# Get AppImage tool and install
RUN wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage && \
    chmod a+x appimagetool-x86_64.AppImage && \
    mv appimagetool-x86_64.AppImage /usr/local/bin && \
    echo "Done"


ENV HOME /root/

WORKDIR $HOME

RUN mkdir apps

WORKDIR $HOME/apps

# We do this ADD to redo following steps if new commits has been added.
ADD https://api.github.com/repos/bjornbytes/lovr/git/refs/heads/master version-lovr.json
ADD https://api.github.com/repos/wallbraker/lovr-apps/git/refs/heads/main version-apps.json
RUN git clone --recurse-submodules https://github.com/bjornbytes/lovr.git && \
    git clone --recurse-submodules https://github.com/wallbraker/lovr-apps.git && \
    echo "Done"

# Do a initial build.
RUN cmake -S lovr -B build \
        -DCMAKE_C_COMPILER=/usr/bin/clang-12 \
        -DCMAKE_CXX_COMPILER=/usr/bin/clang++-12 \
        -DCMAKE_BUILD_TYPE="Release" \
        -G Ninja && \
    ninja -C build && \
    echo Done

# Copy AppImage files to build dir and create AppImage.
RUN cp \
        lovr/etc/AppRun \
        lovr/etc/lovr.desktop \
        lovr/etc/logo.svg \
        build/bin && \
    ls -lah build/bin && \
    appimagetool-x86_64.AppImage --appimage-extract-and-run build/bin && \
    echo Done

RUN mv build/bin/lovr lovr-bin

RUN \
    rm build/bin/lovr.desktop && \
    (cd lovr-apps/overlay && zip -r ../../content.zip . && cd ../..) && \
    cat lovr-bin content.zip > build/bin/lovr && \
    chmod a+x build/bin/lovr && \
    cp lovr-apps/scripts/overlay.desktop build/bin/lovr.desktop && \
    appimagetool-x86_64.AppImage --appimage-extract-and-run build/bin && \
    rm content.zip && \
    echo Done

RUN \
    rm build/bin/lovr.desktop && \
    (cd lovr-apps/hand-vis && zip -r ../../content.zip . && cd ../..) && \
    cat lovr-bin content.zip > build/bin/lovr && \
    chmod a+x build/bin/lovr && \
    cp lovr-apps/scripts/hand-vis.desktop build/bin/lovr.desktop && \
    appimagetool-x86_64.AppImage --appimage-extract-and-run build/bin && \
    rm content.zip && \
    echo Done

RUN \
    echo -n "lovr: " && \
    GIT_DIR=$HOME/apps/lovr/.git git describe --tags --always && \
    echo -n "lovr-apps: " && \
    GIT_DIR=$HOME/apps/lovr-apps/.git git describe --tags --always && \
    ls -lah

WORKDIR $HOME

ENTRYPOINT ["/bin/bash"]
