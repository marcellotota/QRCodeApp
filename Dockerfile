# ================================
# Build image
# ================================
FROM swift:6.1-noble AS build
# Usa immagine ufficiale Swift

# Directory di lavoro
WORKDIR /app

# Copia solo i manifest per sfruttare la cache delle dipendenze
COPY Package*.swift ./

# Monta la cache di Render per le dipendenze Swift
RUN --mount=type=cache,target=/root/.swiftpm \
    --mount=type=cache,target=/root/.build \
    rm -rf .build/ Package.resolved && \
    swift package resolve

# Copia il resto dei sorgenti
COPY Sources ./Sources
COPY Resources ./Resources

# Build con cache
RUN --mount=type=cache,target=/root/.swiftpm \
    --mount=type=cache,target=/root/.build \
    swift build -c release --product QRCodeApp --static-swift-stdlib

# Copia il binario e le risorse in /staging
RUN mkdir -p /staging
RUN cp "$(swift build -c release --show-bin-path)/QRCodeApp" /staging
RUN find -L "$(swift build -c release --show-bin-path)" -regex '.*\.resources$' -exec cp -Ra {} /staging \;

# Entry point
WORKDIR /staging
ENTRYPOINT ["./QRCodeApp"]

