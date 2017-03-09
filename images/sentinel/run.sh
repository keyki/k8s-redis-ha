#!/bin/bash

set -e
set -u
set -x

readonly namespace="$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)"
readonly service_domain="_$SERVICE_PORT._tcp.$SERVICE.$namespace.svc.cluster.local"

redis_info () {
  set +e
  timeout 10 redis-cli -h "$1" -a "$service_domain" info replication
  set -e
}

redis_info_role () {
  echo "$1" | grep -e '^role:' | cut -d':' -f2 | tr -d '[:space:]'
}

domain_ip () {
  dig +noall +answer a "$1" | head -1 | awk -F' ' '{print $NF}'
}

server_domains () {
  dig +noall +answer srv "$1" | awk -F' ' '{print $NF}' | sed 's/\.$//g'
}

run () {
  # It's okay to fail during failover or other unpredictable states.
  # This prevents from making things much worse.

  local -r servers="$(server_domains "$service_domain")"

  local master_ip=''

  local s
  for s in $servers; do
    local s_ip="$(domain_ip "$s")"

    if [ -z "$s_ip" ]; then
      >&2 echo "Failed to resolve: $s"
      continue
    fi

    local i="$(redis_info "$s_ip")"
    if [ -n "$i" ]; then
      if [ "$(redis_info_role "$i")" = 'master' ]; then
        master_ip="$s_ip"
      fi
    else
      >&2 echo "Unable to get Replication INFO: $s ($s_ip)"
      continue
    fi
  done

  if [ -z "$master_ip" ]; then
    >&2 echo "Master not found."
    exit 1
  fi

  cp /sentinel.template.conf /opt/
  cat /sentinel.template.conf | \
    sed "s/%MASTER%/$master_ip/g" | \
    sed "s/%PASSWORD%/$service_domain/g" \
    > /opt/sentinel.conf
  exit 0
}

run