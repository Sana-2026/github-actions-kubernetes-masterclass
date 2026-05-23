# ---------- Stage 1: Builder ----------
FROM golang:1.26-alpine AS builder

WORKDIR /app

# Install git
RUN apk add --no-cache git

# Copy dependency files first
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy remaining source code
COPY . .

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build -mod=mod -o skillpulse .

# ---------- Stage 2: Runtime ----------
FROM alpine:3.23

RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/skillpulse .

EXPOSE 8080

CMD ["./skillpulse"]
