FROM golang:latest

# Install dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates build-essential clang ocl-icd-opencl-dev ocl-icd-libopencl1 jq libhwloc-dev git && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone the lotus repository
RUN git clone --single-branch -b releases https://github.com/filecoin-project/lotus.git lotus-local-net
WORKDIR lotus-local-net
COPY ./lotus.patch ./lotus.patch
RUN git apply lotus.patch
WORKDIR lotus-local-net

# Build lotus
RUN make -C /go/lotus-local-net 2k

# Fetch parameters
RUN /go/lotus-local-net/./lotus fetch-params 2048

# Pre-seal for the first miner
RUN /go/lotus-local-net/./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2 --miner-addr t01000

# Create genesis template
RUN /go/lotus-local-net/./lotus-seed genesis new localnet.json

# Add the first miner to the genesis template
RUN /go/lotus-local-net/./lotus-seed genesis add-miner localnet.json /root/.genesis-sectors/pre-seal-t01000.json

# Pre-seal for the second miner with a unique address
RUN /go/lotus-local-net/./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2 --miner-addr t01001

# Debugging step to check pre-seal files
RUN ls -l /root/.genesis-sectors && cat /root/.genesis-sectors/pre-seal-t01000.json && cat /root/.genesis-sectors/pre-seal-t01001.json

# Add the second miner to the genesis template
RUN /go/lotus-local-net/./lotus-seed genesis add-miner localnet.json /root/.genesis-sectors/pre-seal-t01001.json

# Final debugging step to ensure both miners are added correctly
RUN cat localnet.json
