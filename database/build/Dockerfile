FROM ubuntu:bionic
LABEL maintainer="Rik Janssen"
WORKDIR /surf
COPY . /surf/
RUN apt-get update && apt-get install -y \
    gosu \
    curl \
 && mv rqlite/* /usr/local/bin/ \
 && rm -rf rqlite \
 && chmod +x /surf/init.sh \
 && rm -rf /var/lib/apt/lists/*
EXPOSE 4001/tcp
EXPOSE 4002/tcp
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENTRYPOINT ["/surf/init.sh"]
CMD ["node"]

