FROM alpine:3.19 AS certs
RUN apk --update add ca-certificates

FROM golang:1.27.0 AS build-stage
WORKDIR /build

COPY ./manifest.yaml manifest.yaml

RUN --mount=type=cache,target=/root/.cache/go-build GO111MODULE=on go install go.opentelemetry.io/collector/cmd/builder@v0.164.0
RUN --mount=type=cache,target=/root/.cache/go-build builder --config manifest.yaml

FROM gcr.io/distroless/base:latest

ARG USER_UID=10001
USER ${USER_UID}

COPY ./config.yaml /otelcol/config.yaml
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --chmod=755 --from=build-stage /build/otelcol-clickhouse /otelcol

ENTRYPOINT ["/otelcol/otelcol-clickhouse"]
CMD ["--config", "/otelcol/config.yaml"]

EXPOSE 4317 4318 12001 514 8888 13111
