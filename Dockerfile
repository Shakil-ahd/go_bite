
FROM dart:stable AS build

WORKDIR /app

COPY server/ ./server/

RUN mkdir -p bin && dart compile exe server/server.dart -o bin/server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/bin/server /app/bin/

EXPOSE 8080
CMD ["/app/bin/server"]
