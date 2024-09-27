# Dockerfile to build instrumented version of lotus
FROM golang:latest as builder
# FROM docker.io/golang:latest as builder

# Installing rust
RUN apt-get update && \
    apt-get install -y ca-certificates build-essential clang ocl-icd-opencl-dev ocl-icd-libopencl1 jq libhwloc-dev git && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN git clone https://github.com/filecoin-project/lotus.git /lotus
WORKDIR /lotus
RUN latest_version=$(git tag -l 'v*' | sort -V -r | head -n 1)
RUN git checkout $latest_version
COPY ./lotus.patch ./lotus.patch
COPY ./make.patch ./make.patch
COPY ./pr-11565-reverse.patch ./pr-11565-reverse.patch
RUN git apply lotus.patch
RUN CGO_CFLAGS_ALLOW="-D__BLST_PORTABLE__" \
    CGO_CFLAGS="-D__BLST_PORTABLE__" \
    FFI_USE_BLST_PORTABLE="1" \
    FFI_USE_GPU="0" 


# install the antithesis instrumentation tool
# RUN go get github.com/antithesishq/antithesis-sdk-go@latest
# RUN go install github.com/antithesishq/antithesis-sdk-go/tools/antithesis-go-instrumentor@latest
# RUN go mod tidy
# RUN mkdir /opt/lotus_transformed
# COPY ./exclusion.txt /opt/exclusion.txt
# RUN antithesis-go-instrumentor -exclude /opt/exclusion.txt /opt/lotus /opt/lotus_transformed
# RUN cp -r /opt/lotus/.git /opt/lotus_transformed/customer/

# Building the binaries
# WORKDIR /opt/lotus_transformed/customer
# RUN make lotus
# RUN make lotus-miner
# RUN make lotus-seed
RUN make 2k
RUN sudo make install
RUN ./lotus fetch-params 2048

# Thin runner
# FROM docker.io/golang:1.22.4-bookworm as runner 

# RUN apt-get update && \
# apt-get install -y bash mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config curl clang build-essential hwloc libhwloc-dev wget -y

# RUN mkdir -p /opt/lotus
# COPY --from=builder /opt/lotus_transformed/symbols /symbols
# COPY --from=builder /opt/lotus_transformed/customer/lotus /opt/lotus/lotus
# COPY --from=builder /opt/lotus_transformed/customer/lotus-miner /opt/lotus/lotus-miner
# COPY --from=builder /opt/lotus_transformed/customer/lotus-seed /opt/lotus/lotus-seed

# RUN chmod +x /opt/lotus/lotus
# RUN chmod +x /opt/lotus/lotus-miner
# RUN chmod +x /opt/lotus/lotus-seed

# WORKDIR /opt/lotus

# Some clean up for now
# RUN mv /opt/lotus_transformed/symbols /symbols
# RUN rm -rf /opt/lotus

# Fetch parameters
# RUN ./lotus fetch-params 2048

# # Pre-seal for the first miner
# RUN ./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2 --miner-addr t01000
# # RUN ./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2

# # Create genesis template
# RUN ./lotus-seed genesis new localnet.json

# # Add the first miner to the genesis template
# RUN ./lotus-seed genesis add-miner localnet.json /root/.genesis-sectors/pre-seal-t01000.json

# # # # Pre-seal for the second miner with a unique address
# # RUN ./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2 --miner-addr t01001

# # # # Add the second miner to the genesis template
# # RUN ./lotus-seed genesis add-miner localnet.json /root/.genesis-sectors/pre-seal-t01001.json

ENTRYPOINT ["sleep", "infinity"]