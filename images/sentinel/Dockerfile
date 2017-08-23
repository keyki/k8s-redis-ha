FROM debian:jessie

RUN apt-get update && apt-get install -y bc dnsutils redis-tools
COPY ["sentinel.template.conf", "k8s-redis-ha-sentinel", "run.sh", "/"]

CMD ["/run.sh"]

ENTRYPOINT ["bash", "-c"]
