#!/usr/bin/env bash

get_hostname()
{
  echo -n "Getting the hostname of this machine..."

  HOST=`hostname -f 2>/dev/null`
  if [ "$host" = "" ]; then
    HOST=`hostname 2>/dev/null`
    if [ "$host" = "" ]; then
      HOST=$HOSTNAME
      if [ "$host" = "" ]; then
        HOST=$(curl -s icanhazip.com)
      fi
    fi
  fi

  if [ "$HOST" = "" -o "$HOST" = "(none)" ]; then
    echo "Unable to determine the hostname of your system!"
    echo
    echo "Please consult the documentation for your system. The files you need "
    echo "to modify to do this vary between Linux distribution and version."
    echo
    exit 1
  fi

  echo -n "Found hostname: $HOST"
}
random-string()
{
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}
