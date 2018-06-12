FROM tensorflow/tensorflow

RUN apt-get update && apt-get install -y \ 
    pkg-config \
    python-dev \ 
    python-opencv \ 
    libopencv-dev \ 
    libav-tools  \ 
    libjpeg-dev \ 
    libpng-dev \ 
    libtiff-dev \ 
    libjasper-dev \ 
    python-numpy \ 
    python-pycurl \ 
    python-opencv \
    build-essential \
    cmake \
    gcc 

WORKDIR /

COPY . .
RUN make

ENTRYPOINT [ "./darknet" ]