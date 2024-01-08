#!/bin/bash

# получаем переменные
DOMAIN=$1
DNSBL=$2
TYPE=$3

if [[ $DOMAIN = "" ]]; then
    echo "[{\"Error\": \"No domain\"}]"
    exit
fi

if [[ $DNSBL = "" ]]; then DNSBL="zen.spamhaus.org"; fi
if [[ $TYPE = "" ]]; then TYPE="a"; fi

COUNT=0

# получение данных
case $TYPE in
"mx")
    HOSTIPLIST=$(dig +short $(dig +short MX $DOMAIN))
    ;;
*)
    HOSTIPLIST=$(dig +short $DOMAIN)
    ;;
esac

# парсинг данных
for HOSTIP in $HOSTIPLIST; do
    REVIP=$(sed -r 's/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/\4.\3.\2.\1/' <<<$HOSTIP)
    if [[ $(dig +short $REVIP.$DNSBL) ]]; then
        ((COUNT += 1))
    fi
done

# вывод данных
echo "[{"
echo "\"DNSBL\": \"$COUNT\","
echo "\"IPLIST\": \"$HOSTIPLIST\""
echo "}]"
