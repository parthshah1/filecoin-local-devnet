FROM golang:latest

RUN apt-get update && \
    apt-get install -y ca-certificates build-essential clang ocl-icd-opencl-dev ocl-icd-libopencl1 jq libhwloc-dev git

RUN git clone https://github.com/drand/drand
WORKDIR drand 
RUN make install
