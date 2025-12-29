# ================================
# Build image
# ================================
FROM swift:6.1-noble AS build

# Install OS updates + dependencies for SwiftGD (gd.h)
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y \
        libgd-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# Resolve dependencies first (better Docker cache)
COPY ./Package.* ./
RUN swift package resolve \
    $([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)

# Copy entire repo into container
COPY . .

# Staging area
RUN mkdir /staging

# Build the application (NO jemalloc)
RUN --mount=type=cache,target=/build/.build \
    swift build -c release \
        --product QRCodeApp \
        --static-swift-stdlib && \
    # Copy main executable to staging area
    cp "$(swift build -c release --show-bin-path)/QRCodeApp" /staging && \
    # Copy resources bundled by SPM to staging area
    find -L "$(swift build -c release --show-bin-path)" -regex '.*\.resources$' -exec cp -Ra {} /staging \;

# Switch to the staging area
WORKDIR /staging

# Copy static swift backtracer binary
RUN cp "/usr/libexec/swift/linux/swift-backtrace-static" ./

# Copy Public / Resources if present (read-only)
RUN [ -d /build/Public ] && { mv /build/Public ./Public && chmod -R a-w ./Public; } || true
RUN [ -d /build/Resources ] && { mv /build/Resources ./Resources && chmod -R a-w ./Resources; } || true

# ================================
# Run image
# ================================
FROM ubuntu:noble

# Install runtime dependencies (libgd runtime, NO jemalloc)
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
        libgd3 \
        libpng16-16 \
        libjpeg-turbo8 \
        libfreetype6 \
        ca-certificates \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

# Create vapor user
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

# App directory
WORKDIR /app

# Copy built executable and resources
COPY --from=build --chown=vapor:vapor /staging /app

# Swift backtrace config
ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

# Run as vapor user
USER vapor:vapor

# Vapor default port
EXPOSE 8080

# Start Vapor
ENTRYPOINT ["./QRCodeApp"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
