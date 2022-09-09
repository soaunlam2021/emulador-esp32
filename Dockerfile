########################################################################
# Archivo: DockerFile ESP32
# Descripción: Genera el contenedor Docker con el compilador y emulador de ESP32
# Uso: docker build --tag "soaunlam/qemu_esp32:latest" --file Dockerfile_esp32_v1.txt . --no-cache
########################################################################


#---------- Instala Ubuntu base y dependencias -------------------------

# Se descarga la version de Ubuntu 20.04
#FROM ubuntu:22.04
FROM ubuntu:18.04

ENV TZ=America/Buenos_Aires
#ENV TZ=Europe/Moscow
ENV DEBIAN_FRONTEND="noninteractive"

# Instalo los paquetes basicos de Ubuntu
RUN apt-get update -y && apt-get install -y --no-install-recommends \
# Paquetes recomendados para bajar los repositorios gits.
            openssh-server ca-certificates ssh wget git flex bison gperf unzip screen      \
# Paquetes recomendados para trabajar con idf.
            libusb-1.0-0  libffi-dev libssl-dev dfu-util \
            python2.7 python3 python3-pip python-setuptools cmake ninja-build ccache \
# Paquetes para compilar Qemu
            libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev ninja-build gcc make g++

#----------- Instalar modulos python -----------------------------------
#RUN python2 -m pip install --upgrade python-socketio==4.6.0 click gdbgui pip virtualenv
#RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py -O get-pip.py; \
#    /usr/bin/python2.7 get-pip.py; \
#RUN pip install --upgrade pip; \
#    pip install python-engineio==3.11.2 python-socketio==4.4.0 click gdbgui virtualenv

RUN pip3 install --upgrade pip; \
    pip3 install python-engineio python-socketio click gdbgui virtualenv
            
#----------- Configurar el ssh -----------------------------------------

RUN set -eux;                                                                                 \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config; \
    sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config;  \
# Se establece el password root
    echo 'root:1234' | chpasswd;                                                              \
# Reinciar el servicio ssh
    service ssh restart

# Defino el directorio de trabajo
WORKDIR /opt

ENV IDF_PATH=/opt/esp-idf

#----------- Instalar Qemu esp32 -----------------------------------------
# https://github.com/Ebiroll/qemu_esp32
RUN git clone https://github.com/Ebiroll/qemu-xtensa-esp32; \
    git clone https://github.com/Ebiroll/qemu_esp32;  \
    cd qemu_esp32; \
    ../qemu-xtensa-esp32/configure --disable-werror --prefix=`pwd`/root --target-list=xtensa-softmmu,xtensaeb-softmmu --python=/usr/bin/python2.7; \
    make; \
    gcc /opt/qemu_esp32/toflash.c -o /opt/qemu_esp32/qemu_flash; \
    cd  /opt/qemu_esp32/roms; \
    wget https://www.so-unlam.com.ar/material-investigacion/Docker/Roms/rom.bin; \
    wget https://www.so-unlam.com.ar/material-investigacion/Docker/Roms/rom1.bin

#----------- Configurar el paquete esp-idf -----------------------------
# https://github.com/espressif/esp-idf

# Obtengo el paquere idf version 4.4, para compilar esp32.
RUN git clone -b v4.4.1 --recursive https://github.com/espressif/esp-idf.git esp-idf;  \
    export PATH="$PATH:$IDF_PATH/tools:/root/.local/bin";                       \
    ${IDF_PATH}/install.sh esp32;                                                \
    echo "#!/usr/bin/env bash\\nset -e\\n. \$IDF_PATH/export.sh\\nexec \"\$@\"" > ${IDF_PATH}/entrypoint.sh; \
#    cat ${IDF_PATH}/entrypoint.sh; \
    chmod +x ${IDF_PATH}/entrypoint.sh

ENTRYPOINT [ "/opt/esp-idf/entrypoint.sh" ]
CMD [ "/bin/bash" ]
