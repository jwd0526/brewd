FROM golang:1.25.4-alpine AS builder

WORKDIR /

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN go build -o bin/brewd-backend ./cmd/server

FROM alpine:3.22

WORKDIR /

COPY --from=builder bin/brewd-backend /bin/brewd-backend

CMD ["/bin/brewd-backend"]