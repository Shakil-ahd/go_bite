# Use the official Dart image
FROM dart:stable AS build

# Resolve app dependencies
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code and AOT compile it
COPY . .
# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
RUN dart compile exe server/server.dart -o bin/server

# Build minimal serving image
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/bin/server /app/bin/

# Start server
EXPOSE 8080
CMD ["/app/bin/server"]
