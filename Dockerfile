# ================================
# Build image
# ================================
FROM swift:6.1-noble AS build

WORKDIR /app

# Copia manifest per cache dipendenze
COPY Package.swift Package.resolved ./

RUN --mount=type=cache,target=/root/.swiftpm \
    --mount=type=cache,target=/root/.build \
    swift package resolve

# Copia sorgenti e risorse
COPY Sources ./Sources
COPY Resources ./Resources
COPY Public ./Public
COPY Tests ./Tests

# Build release
RUN --mount=type=cache,target=/root/.swiftpm \
    --mount=type=cache,target=/root/.build \
    swift build -c release --product QRCodeApp


# ================================
# Runtime image (Swift necessario)
# ================================
FROM swift:6.1-noble

WORKDIR /app

# Copia binario
COPY --from=build /app/.build/release/QRCodeApp ./QRCodeApp

# Copia risorse Leaf
COPY --from=build /app/Resources ./Resources

# Copia file statici (CSS / immagini / JS)
COPY --from=build /app/Public ./Public

# Render usa PORT
ENV PORT=8080
EXPOSE 8080

# Avvio app Vapor
CMD ["./QRCodeApp"]
