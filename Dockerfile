# ================================
# Build image
# ================================
FROM swift:6.1-noble AS build

# Directory di lavoro
WORKDIR /app

# Copia solo i manifest per sfruttare la cache delle dipendenze
COPY Package.swift Package.resolved ./

# Cache SwiftPM (Render)
RUN --mount=type=cache,target=/root/.swiftpm \
    --mount=type=cache,target=/root/.build \
    swift package resolve

# Copia sorgenti, risorse e test
COPY Sources ./Sources
COPY Resources ./Resources
COPY Tests ./Tests

# Build release (❌ niente static-swift-stdlib)
RUN --mount=type=cache,target=/root/.swiftpm \
    --mount=type=cache,target=/root/.build \
    swift build -c release --product QRCodeApp

# ================================
# Runtime image
# ================================
FROM ubuntu:24.04

WORKDIR /app

# Dipendenze runtime minime
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Copia binario
COPY --from=build /app/.build/release/QRCodeApp ./QRCodeApp

# 🔥 COPIA ESPLICITA DELLE RISORSE (VIEWS LEAF)
COPY --from=build /app/Resources ./Resources

# Render fornisce PORT
ENV PORT=8080

EXPOSE 8080

CMD ["./QRCodeApp"]
