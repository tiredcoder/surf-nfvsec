FROM ubuntu:bionic
LABEL maintainer="Rik Janssen"
WORKDIR /surf
COPY . /surf/
RUN apt-get update && apt-get install -y \
    gosu \
    tcpdump \
    curl \
 && chmod +x /surf/init.sh \
 && rm -rf /var/lib/apt/lists/*
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV VNF_CLASS="FaaS"
ENV VNF_VERSION="1.0"
ENTRYPOINT ["/surf/init.sh"]
CMD ["default"]

