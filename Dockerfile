FROM golang:1.14-alpine AS go-builder
LABEL maintainer="Nabendu Maiti <nbmaiti83@gmail.com>"

ENV DOCKER_GEN_VERSION=0.7.4

# Install build dependencies for docker-gen
RUN apk add --update \
        curl \
        gcc \
        git \
        make \
        musl-dev

# Build docker-gen
RUN go get github.com/jwilder/docker-gen \
    && cd /go/src/github.com/jwilder/docker-gen \
    && git checkout $DOCKER_GEN_VERSION \
    && make get-deps \
    && make all


FROM nginx:1.19.3
LABEL maintainer="Jason Wilder mail@jasonwilder.com"

# Install wget and install/updates certificates
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*


# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/worker_processes  1/worker_processes  auto/' /etc/nginx/nginx.conf

# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

ENV DOCKER_GEN_VERSION 0.7.4

COPY --from=go-builder /go/src/github.com/jwilder/docker-gen/docker-gen /usr/local/bin/

COPY network_internal.conf /etc/nginx/

COPY . /app/
WORKDIR /app/

ENV DOCKER_HOST unix:///tmp/docker.sock

VOLUME ["/etc/nginx/certs", "/etc/nginx/dhparam"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
