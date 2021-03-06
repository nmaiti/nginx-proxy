FROM --platform=linux/amd64 golang:1.14 AS go-builder
LABEL maintainer="Nabendu Maiti <nbmaiti83@gmail.com>"

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

ENV DOCKER_GEN_VERSION=0.7.4
ENV FOREGO_VERSION=v0.16.1

# Install build dependencies for docker-gen
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
        curl \
        gcc \
        git \
        make 

# Build docker-gen
RUN go get github.com/jwilder/docker-gen \
    && cd /go/src/github.com/jwilder/docker-gen \
#    && git checkout $DOCKER_GEN_VERSION \
	&& make get-deps \
	&& case "$TARGETVARIANT" in  \
			v7) export GOARM='6' ;; \
			v6) export GOARM='5' ;; \
			*) echo "nothing here" ;;\
		esac \
	&& GOOS=$TARGETOS  GOARCH=$TARGETARCH go build ./cmd/docker-gen

# build forego
RUN cd /go/src  \
	&& git clone https://github.com/ddollar/forego \
	&& cd forego \
	&& case "$TARGETVARIANT" in  \
		v7) export GOARM='6' ;; \
		v6) export GOARM='5' ;; \
		*) echo "nothing here" ;;\
	 esac \
	&& GOOS=$TARGETOS GOARCH=$TARGETARCH go build


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

# copy forego and docker-gen
COPY --from=go-builder /go/src/forego/forego /usr/local/bin/
RUN chmod u+x /usr/local/bin/forego
COPY --from=go-builder /go/src/github.com/jwilder/docker-gen/docker-gen /usr/local/bin/
RUN chmod u+x /usr/local/bin/docker-gen

COPY network_internal.conf /etc/nginx/

COPY . /app/
WORKDIR /app/

ENV DOCKER_HOST unix:///tmp/docker.sock

VOLUME ["/etc/nginx/certs", "/etc/nginx/dhparam"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
