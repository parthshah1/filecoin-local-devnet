# Dockerfile to build instrumented version of lotus
FROM golang:latest as builder

# Install necessary packages and Rust
RUN apt-get update && \
    apt-get install -y ca-certificates build-essential clang ocl-icd-opencl-dev ocl-icd-libopencl1 jq libhwloc-dev git && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone the Lotus repository
RUN git clone https://github.com/filecoin-project/lotus.git /lotus
RUN export LOTUS_PATH=~/.lotus-local-net && \
    export LOTUS_MINER_PATH=~/.lotus-miner-local-net && \
    export LOTUS_SKIP_GENESIS_CHECK=_yes_ && \
    export CGO_CFLAGS_ALLOW="-D__BLST_PORTABLE__" && \
    export CGO_CFLAGS="-D__BLST_PORTABLE__"
WORKDIR /lotus

# Checkout the specified or latest Lotus version
ARG LOTUS_VERSION
RUN if [ -z "$LOTUS_VERSION" ]; then \
    LATEST_RELEASE=$(git tag -l 'v*' | grep -v "-" | sort -V -r | head -n 1); \
    git checkout $LATEST_RELEASE; \
else \
    git checkout $LOTUS_VERSION; \
fi

COPY ./lotus.patch ./lotus.patch
RUN git apply lotus.patch
RUN git submodule update --init
RUN go get github.com/antithesishq/antithesis-sdk-go@latest
RUN go install github.com/antithesishq/antithesis-sdk-go/tools/antithesis-go-instrumentor@latest
RUN go mod tidy

RUN mkdir ../lotus_transformed
COPY ./exclusion.txt .
RUN cd ..
RUN antithesis-go-instrumentor -exclude /lotus/exclusion.txt /lotus /lotus_transformed
RUN cp -r /lotus/.git /lotus_transformed/customer/

WORKDIR /lotus_transformed/customer
#Build the project
RUN make 2k
RUN mv ../symbols /symbols
COPY ./config.toml .
RUN rm -rf /lotus


# Fetch parameters for the network
RUN ./lotus fetch-params 2048

# Pre-seal sectors for the first miner
RUN ./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2 --miner-addr t01000

# Create and configure the genesis template
RUN ./lotus-seed genesis new localnet.json 
RUN ./lotus-seed genesis add-miner localnet.json /root/.genesis-sectors/pre-seal-t01000.json
RUN make install



ENTRYPOINT ["sleep", "infinity"]