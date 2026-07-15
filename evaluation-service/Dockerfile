FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -o /evaluation-service .

FROM alpine:3.19

RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /evaluation-service .

EXPOSE 8004

ENTRYPOINT ["./evaluation-service"]
