#!/bin/bash

# получаем переменные
DOMAIN=$1
PORT=$2
TYPE=$3

if [[ $DOMAIN = "" ]]; then
    echo "[{\"Error\": \"No domain\"}]"
    exit
fi

if [[ $PORT = "" ]]; then PORT="443"; fi
if [[ $TYPE = "" ]]; then TYPE="web"; fi

# Подержка Internationalized Domain Names (IDN)
# CentOS 9: dnf install idn2

DOMAIN=$(echo $DOMAIN | idn2)

# получение SSL
case $TYPE in
"ftp")
    SSL=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:$PORT -tls1_2 -starttls ftp 2>/dev/null | openssl x509 -issuer -dates -subject -email -serial -fingerprint -noout -text 2>/dev/null)
    ;;
"smtp")
    SSL=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:$PORT -tls1_2 -starttls smtp 2>/dev/null | openssl x509 -issuer -dates -subject -email -serial -fingerprint -noout -text 2>/dev/null)
    ;;
*)
    SSL=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:$PORT 2>/dev/null | openssl x509 -issuer -dates -subject -email -serial -fingerprint -noout -text 2>/dev/null)
    ;;
esac

# парсинг данных
if [[ $SSL = "" ]]; then
    echo "[{\"Error\": \"No SSL response\"}]"
    exit
else
    CURRENTDATE=$(LANG=en_EN TZ=GMT date +"%b %d %R:%S %Y %Z")
    ISSUER=$(echo "$SSL" | grep "issuer=" | cut -b 8- | sed 's/"/\\\"/g')
    NOTBEFORE=$(echo "$SSL" | grep "notBefore=" | cut -b 11-)
    NOTAFTER=$(echo "$SSL" | grep "notAfter=" | cut -b 10-)
    VALIDNOTAFTER=$(
        LANG=en_EN TZ=GMT date -d "$NOTAFTER" >/dev/null 2>&1
        echo $?
    )
    DIFFDAYS=-1
    if [[ $VALIDNOTAFTER == 0 ]]; then DIFFDAYS=$(LANG=en_EN TZ=GMT echo $((($(date -d "$NOTAFTER" +"%s") - $(date -d "$CURRENTDATE" +"%s")) / 86400))); fi
    SUBJECT=$(echo "$SSL" | grep "subject=" | cut -b 9-)
    EMAIL=$(echo "$SSL" | grep "email=" | cut -b 7-)
    SERIAL=$(echo "$SSL" | grep "serial=" | cut -b 8-)
    FINGERPRINT=$(echo "$SSL" | grep "SHA1 Fingerprint=" | cut -b 18-)
    VER=$(echo "$SSL" | grep "Version: " | sed -e 's/^[ \t]*//' | cut -b 10-)
    ALGORITHM=$(echo "$SSL" | grep -m 1 "Signature Algorithm: " | sed -e 's/^[ \t]*//' | cut -b 22-)
    PUBALGORITHM=$(echo "$SSL" | grep "Public Key Algorithm: " | sed -e 's/^[ \t]*//' | cut -b 23-)
    ALT=$(echo "$SSL" | grep -A 1 "Subject Alternative Name" | grep -v "Subject Alternative Name" | sed -e 's/^[ \t]*//')
fi

# вывод данных
echo "[{"
echo "\"Domain\": \"$DOMAIN\","
echo "\"Port\": \"$PORT\","
echo "\"Type\": \"$TYPE\","
echo "\"Issuer\": \"$ISSUER\","
echo "\"NotBefore\": \"$NOTBEFORE\","
echo "\"NotAfter\": \"$NOTAFTER\","
echo "\"Subject\": \"$SUBJECT\","
echo "\"Email\": \"$EMAIL\","
echo "\"Serial\": \"$SERIAL\","
echo "\"Fingerprint\": \"$FINGERPRINT\","
echo "\"Version\": \"$VER\","
echo "\"SignatureAlgorithm\": \"$ALGORITHM\","
echo "\"PublicKeyAlgorithm\": \"$PUBALGORITHM\","
echo "\"AlternativeName\": \"$ALT\","
echo "\"Days\": \"$DIFFDAYS\""
echo "}]"
