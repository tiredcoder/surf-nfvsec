FROM ubuntu:bionic
LABEL maintainer="Rik Janssen"
WORKDIR /surf
COPY . /surf/
RUN apt-get update && apt-get install -y \
    gosu \
    openssh-client \
    curl \
    python3 \
    python3-pip \
 && pip3 install --trusted-host pypi.python.org Flask==1.0.2 ./pyrqlite \
 && rm -rf ./pyrqlite \
 && chmod +x /surf/init.sh \
 && chmod +x /surf/app/lb-ctrl.sh \
 && rm -rf /var/lib/apt/lists/*
EXPOSE 80
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENTRYPOINT ["/surf/init.sh"]
CMD ["default"]

