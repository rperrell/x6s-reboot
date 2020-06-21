#!/usr/bin/env bash
#
# A simple bash script for rebooting a Netgear Nighthawk X6S Extender
#
# https://github.com/rperrell/x6s-reboot

set -e

CURL_OPT="--connect-timeout 10"

trap 'catch $? $LINENO' ERR

catch() {
  [ $1 -eq 28 ] && echo "Connection timeout"
  exit $1
}

usage() { echo "Usage: x6s-reboot [options...] [host]"; }

while getopts ":hp:tu:" opt; do
  case $opt in
    h )
      usage
      echo "    -h            Print this help text"
      echo "    -p <password> Set the username"
      echo "    -t            Test connection"
      echo "    -u <username> Set the password"
      exit 0
      ;;
    p )
      PASSWORD=$(echo -n $OPTARG | base64 | tr -d '=')
      ;;
    u )
      EMAIL=$(echo -n $OPTARG | base64 | tr -d '=')
      ;;
    t )
      TEST=1
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage
      exit 1
      ;;
    : )
      echo "Option -$OPTARG requires an argument" 1>&2
      usage
      exit 1
      ;;
    * )
      echo "Invalid option or argument" 1>&2
      exit 1
      ;;
  esac
done

shift $((OPTIND -1))

HOST=$1

if [ -z "$HOST" ]; then
  read -p "host: " HOST
fi

if [ -z "$EMAIL" ]; then
  read -p "username: "
  EMAIL=$(echo -n "$REPLY" | base64 | tr -d '=')
fi

if [ -z "$PASSWORD" ]; then
  read -sp "password: "
  PASSWORD=$(echo -n "$REPLY" | base64 | tr -d '=')
fi

curl $CURL_OPT -s -d 'submit_flag=login' -d "email=$EMAIL" -d "password=$PASSWORD" -d 'hid_remember_me=off' -X POST "http://$HOST/register.cgi?/status.htm" >/dev/null

TIMESTAMP=$(curl $CURL_OPT -s http://$HOST/backUpSettings.htm | grep timestamp= | grep langForm | cut -f 5 -d ' ' | tr -d '"' | cut -f 2 -d '=')

[ -z "$TIMESTAMP" ] && echo Connection failed && exit 1

[ "$TEST" ] && echo Connection successful && exit 0

curl $CURL_OPT -s -d 'submit_flag=reboot'  "http://$HOST/admin.cgi?/status.htm%20timestamp=$TIMESTAMP" >/dev/null

echo Rebooting
