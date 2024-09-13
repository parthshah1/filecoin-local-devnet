FROM docker.io/golang:1.22.4-bookworm as builder

# Step 1: Install dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends jq -y build-essential clang curl git ca-certificates && \
    update-ca-certificates

# Step 2: Install Rust (this is cached unless Rust changes)
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

# Step 3: Clone the repository (this is cached unless the repository changes)
RUN git clone https://github.com/chainsafe/forest /opt/forest
WORKDIR /opt/forest

# Step 4: Copy and apply the patch (this changes more frequently, so it's placed later)
COPY ./forest.patch ./forest.patch
RUN git apply forest.patch

# Step 5: Build and install the project
RUN make install

# Step 6: Set up environment variables and fetch necessary parameters
ENV FIL_PROOFS_PARAMETER_CACHE="/var/tmp/filecoin-proof-parameters"
RUN forest-tool fetch-params --keys

# Step 7: Cache actor bundle
ENV FOREST_ACTOR_BUNDLE_PATH="/var/tmp/forest_actor_bundle.car.zst"
RUN forest-tool state-migration actor-bundle $FOREST_ACTOR_BUNDLE_PATH

# Step 8: Keep the container alive
ENTRYPOINT ["sleep", "infinity"]

