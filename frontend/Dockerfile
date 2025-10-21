FROM node:24-alpine

# Install nginx and curl
# hadolint ignore=DL3018
RUN apk add --no-cache nginx curl

# Change working directory
WORKDIR /app

# Copy prebuilt assets from out dir
COPY out /usr/share/nginx/html

# Copy config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 3000

CMD ["./entrypoint.sh"]