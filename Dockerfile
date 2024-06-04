FROM registry.gitlab.com/emulation-as-a-service/emulators/emulators-base

LABEL "org.opencontainers.image.source"="https://github.com/iimcz/eaas-qemu-gpu"
LABEL "EAAS_EMULATOR_TYPE"="gpu-qemu-system"
LABEL "EAAS_EMULATOR_VERSION"="v0.1"


ENV QEMU_VERSION="8.2.2"

ENV EDK2_VERSION="edk2-stable202405"
ENV EDK2_CONFIG_PLATFORM_SED="s#ACTIVE_PLATFORM\\s+=.*#ACTIVE_PLATFORM = OvmfPkg/OvmfPkgX64.dsc#"
ENV EDK2_CONFIG_ARCH_SED="s#TARGET_ARCH\\s+=.*#TARGET_ARCH = X64#"
ENV EDK2_CONFIG_TOOL_SED="s#TOOL_CHAIN_TAG\\s+=.*#TOOL_CHAIN_TAG = GCC5#"
ENV EDK2_CONFIG_TARGET_SED="s#TARGET\\s+=.*#TARGET = RELEASE#"

ENV BM_VERSION=12.4.1
ENV BM_PACKAGE_VERSION=12.4.1a15
ENV BLACKMAGIC_SDK_ARCHIVE_DIR="Blackmagic DeckLink SDK ${BM_VERSION}"
ENV BLACKMAGIC_DECKLINK_SDK="/opt/BM_SDK"
ENV BM_INCLUDE="${BLACKMAGIC_DECKLINK_SDK}/include"

ENV FFMPEG_VERSION="7.0.1"


RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes \
build-essential vde2 \
libvde-dev libvdeplug-dev libvdeplug2 libvde0 python3 bison flex libx11-dev \
python3-sphinx ninja-build libglib2.0-dev libseccomp-dev libvdeplug-dev sparse python3-sphinx-rtd-theme libnfs-dev \
libpixman-1-dev libsndio-dev libpulse-dev libaio-dev libcap-ng-dev libxkbcommon-dev libslirp-dev \
libspice-server-dev libspice-protocol-dev libsndio-dev libvirglrenderer-dev libzstd-dev libiscsi-dev \
zlib1g-dev libudev-dev libcurl4-gnutls-dev libepoxy-dev libssh-dev libsdl2-dev cmake cmake-extras \
libusb-dev libgbm-dev libjpeg-dev libpng-dev libusb-1.0-0-dev libusbredirparser-dev libibumad-dev \
libibverbs-dev python3-venv git nasm libc++-dev uuid-dev iasl python-is-python3

# Download, compile and install QEMU with KVM, vgl GPU and passthrough support
WORKDIR /qemu
RUN curl "https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz" | tar xJ --strip-components=1
RUN ./configure --prefix=/usr --enable-lto --target-list=x86_64-softmmu,i386-softmmu \
--enable-virglrenderer --enable-vde --enable-spice --enable-opengl --enable-kvm --enable-libusb && make install

# Download, compile and prepare the OVMF UEFI firmwave for VMs
WORKDIR /edk2
# First update NASM to the required minimal version for edk2
RUN curl -L -o nasm.deb http://cz.archive.ubuntu.com/ubuntu/pool/universe/n/nasm/nasm_2.15.05-1_amd64.deb && dpkg -i nasm.deb && rm nasm.deb
RUN git clone --recursive --depth=1 --branch "${EDK2_VERSION}" https://github.com/tianocore/edk2.git . && make -C BaseTools \
&& . /edk2/edksetup.sh && sed -i -E -e "${EDK2_CONFIG_PLATFORM_SED}" -e "${EDK2_CONFIG_ARCH_SED}" -e "${EDK2_CONFIG_TOOL_SED}" -e "${EDK2_CONFIG_TARGET_SED}" Conf/target.txt \
&& build && mkdir -p /opt/ovmf && mv Build/OvmfX64/RELEASE_GCC5/FV/OVMF*.fd /opt/ovmf/

# Add, extract and install Blackmagic SDK and drivers to use with ffmpeg
#WORKDIR /thirdparty

# TODO: Decide if we want to run ffmpeg in the container or outside as a system dependency. This will also affect if we need the Blackmagic runtime and SDK.

#ADD thirdparty /thirdparty
#RUN unzip Blackmagic_DeckLink_SDK_${BM_VERSION}.zip -d /opt && mv "/opt/${BLACKMAGIC_SDK_ARCHIVE_DIR}/Linux" "${BLACKMAGIC_DECKLINK_SDK}" && rm -r "/opt/${BLACKMAGIC_SDK_ARCHIVE_DIR}"
#RUN tar xf Blackmagic_Desktop_Video_Linux_${BM_VERSION}.tar.tar && tar xvzf Blackmagic_Desktop_Video_Linux_${BM_VERSION}/other/x86_64/desktopvideo-${BM_PACKAGE_VERSION}-x86_64.tar.gz
#RUN install -t /usr/lib desktopvideo-${BM_PACKAGE_VERSION}-x86_64/usr/lib/*.so

# Download, compile and run Ffmpeg with support for Blackmagic hurdware
#WORKDIR /ffmpeg
#
#RUN curl "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz" | tar xJ --strip-components=1
#RUN ./configure --prefix=/usr --extra-cflags="-I${BM_INCLUDE}" --enable-decklink && make install || cat /ffmpeg/ffbuild/config.log

WORKDIR /

RUN rm -rf /qemu && rm -rf /edk2 && apt-get clean

ADD metadata /metadata
