# ================================
# Build image
# ================================
FROM swift:6.1-noble AS build

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y \
        libgd-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        pkg-config \
    && [ -f /usr/include/gd.h ] || ln -s /usr/include/gd2/gd.h /usr/include/gd.h
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY ./Package.* ./
RUN swift package resolve

COPY . .

RUN mkdir /staging

RUN --mount=type=cache,target=/build/.build \
    swift build -c release \
        --product QRCodeApp \
        --static-swift-stdlib && \
    cp "$(swift build -c release --show-bin-path)/QRCodeApp" /staging && \
    find -L "$(swift build -c release --show-bin-path)" -regex '.*\.resources$' -exec cp -Ra {} /staging \;

WORKDIR /staging
RUN cp "/usr/libexec/swift/linux/swift-backtrace-static" ./

RUN [ -d /build/Public ] && mv /build/Public ./Public || true
RUN [ -d /build/Resources ] && mv /build/Resources ./Resources || true

# ================================
# Run image
# ================================
FROM ubuntu:noble

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y \
        libgd3 \
        libpng16-16 \
        libjpeg-turbo8 \
        libfreetype6 \
        ca-certificates \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --user-group --create-home --system --home-dir /app vapor

WORKDIR /app
COPY --from=build --chown=vapor:vapor /staging /app

ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes

USER vapor:vapor

EXPOSE 8080
ENTRYPOINT ["./QRCodeApp"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
