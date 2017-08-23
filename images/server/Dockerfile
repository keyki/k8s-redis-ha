FROM debian:jessie

RUN apt-get update && apt-get install -y bc dnsutils redis-tools
COPY ["redis.template.conf", "k8s-redis-ha-server", "run.sh", "/"]

CMD ["/run.sh"]

ENTRYPOINT ["bash", "-c"]
