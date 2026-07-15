FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -o /auth-service .

FROM alpine:3.19

RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /auth-service .

EXPOSE 8001

ENTRYPOINT ["./auth-service"]
