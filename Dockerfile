FROM python:3.6

RUN apt-get update && \
        apt-get install -y \
        build-essential \
        cmake \
        git \
        wget \
        unzip \
        yasm \
        pkg-config \
        libswscale-dev \
        libtbb2 \
        libtbb-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libavformat-dev \
        libpq-dev \
        libgtk2.0-dev

RUN git clone https://github.com/jasperproject/jasper-client.git jasper \ 
    && chmod +x jasper/jasper.py \ 
    && pip install --upgrade setuptools \ 
    && pip install -r jasper/client/requirements.txt

RUN pip install numpy

WORKDIR /

ENV OPENCV_VERSION="3.4.0"
RUN wget https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip \
    && unzip ${OPENCV_VERSION}.zip \
    && rm ${OPENCV_VERSION}.zip
RUN wget https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip \
    && unzip ${OPENCV_VERSION}.zip \
    && mkdir /opencv-${OPENCV_VERSION}/cmake_binary \
    && cd /opencv-${OPENCV_VERSION}/cmake_binary \
    && cmake -DBUILD_TIFF=ON \
    -DBUILD_opencv_java=OFF \
    -DOPENCV_EXTRA_MODULES_PATH=/opencv_contrib-${OPENCV_VERSION}/modules \
    -DWITH_CUDA=OFF \
    -DENABLE_AVX=ON \
    -DWITH_OPENGL=ON \
    -DWITH_OPENCL=ON \
    -DWITH_IPP=ON \
    -DWITH_TBB=ON \
    -DWITH_EIGEN=ON \
    -DWITH_V4L=ON \
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=$(python3.6 -c "import sys; print(sys.prefix)") \
    -DPYTHON_EXECUTABLE=$(which python3.6) \
    -DPYTHON_INCLUDE_DIR=$(python3.6 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
    -DPYTHON_PACKAGES_PATH=$(python3.6 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") .. \
    && make -j8 \
    && make install \
    && rm /${OPENCV_VERSION}.zip \
    && rm -r /opencv-${OPENCV_VERSION}

COPY opencv.conf /etc/ld.so.conf.d/
RUN ldconfig -v

## install filebeat
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - \
    && apt-get install apt-transport-https \
    && echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-6.x.list \
    && apt-get update \
    && apt-get install -y filebeat \
    && update-rc.d filebeat defaults 95 10

COPY . .
RUN make

ENV LD_LIBRARY_PATH="./:${LD_LIBRARY_PATH}"

COPY filebeat.yml /etc/filebeat/
RUN chmod go-w /etc/filebeat/filebeat.yml

ENTRYPOINT [ "./uselib" ]