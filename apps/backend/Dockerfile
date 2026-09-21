# Build Stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

COPY go.mod ./
RUN go mod tidy
RUN go mod download

COPY . .

RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o catat-api ./cmd/api

# Final Stage
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Jakarta

WORKDIR /root/

COPY --from=builder /app/catat-api .
COPY --from=builder /app/db/migrations ./db/migrations

EXPOSE 8080

CMD ["./catat-api"]
