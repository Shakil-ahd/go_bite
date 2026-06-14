# Use the official Dart image
FROM dart:stable AS build

WORKDIR /app

# Copy the server directory specifically
COPY server/ ./server/

# Compile the server directly (no pubspec needed since it uses only dart:io and dart:convert)
RUN mkdir -p bin && dart compile exe server/server.dart -o bin/server

# Build minimal serving image
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/bin/server /app/bin/

# Start server
EXPOSE 8080
CMD ["/app/bin/server"]
