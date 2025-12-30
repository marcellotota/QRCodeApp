# ================================
# Build image
# ================================
FROM swift:6.1-noble AS build

WORKDIR /app

# Manifest
COPY Package.swift Package.resolved ./

RUN --mount=type=cache,target=/root/.swiftpm \
    --mount=type=cache,target=/root/.build \
    swift package resolve

# Sorgenti
COPY Sources ./Sources
COPY Resources ./Resources
COPY Tests ./Tests

# Build release
RUN --mount=type=cache,target=/root/.swiftpm \
    --mount=type=cache,target=/root/.build \
    swift build -c release --product QRCodeApp

# ================================
# Runtime image (⚠️ SEMPRE SWIFT)
# ================================
FROM swift:6.1-noble

WORKDIR /app

# Copia binario
COPY --from=build /app/.build/release/QRCodeApp ./QRCodeApp

# Copia Resources (Leaf!)
COPY --from=build /app/Resources ./Resources

# Render usa PORT
ENV PORT=8080
EXPOSE 8080

CMD ["./QRCodeApp"]
