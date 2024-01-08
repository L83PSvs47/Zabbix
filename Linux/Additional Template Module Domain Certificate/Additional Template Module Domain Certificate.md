---
title: '202312110954'
author: 
description: Проверка срока истечения сертификата домена
created: 2023-12-11 09:54
updated: 2023-12-11 15:29
links: ['[Zabbix — мониторинг SSL сертификатов (3) | internet-lab.ru](https://internet-lab.ru/zabbix_ssl_check)']
tags: [zabbix, linux, bash, script, certificate, expiration, monitoring, template]
aliases: []
---

Для получения данных о сроках действия сертификата домена будет использоваться небольшой bash скрипт. Для его работы на сервере Zabbix (или Zabbix прокси) потребуется `openssl`.

Проверьте в конфигурационном файле `/etc/zabbix/zabbix_server.conf` (если будет запускаться на сервере Zabbix) или `/etc/zabbix/zabbix_proxy.conf` (если будет запускаться на Zabbix прокси) путь к каталогу для внешних скриптов. По умолчанию это `ExternalScripts=/usr/lib/zabbix/externalscripts` (нужно раскомментировать строку или указать новый путь).

Создайте в этом каталоге файл `get-domain-certificate.sh`:

```shell
vi /usr/lib/zabbix/externalscripts/get-domain-certificate.sh
```

Добавьте в созданный файл код:

```shell
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
```

Разрешить запуск скрипта:

```shell
chmod +x /usr/lib/zabbix/externalscripts/get-domain-certificate.sh
```

Проверить работу скрипта:

```shell
/usr/lib/zabbix/externalscripts/get-domain-certificate.sh example.com 443 web
```

```info
[{
"Domain": "example.com",
"Port": "443",
"Type": "web",
"Issuer": "C = US, O = DigiCert Inc, CN = DigiCert TLS RSA SHA256 2020 CA1",
"NotBefore": "Jan 13 00:00:00 2023 GMT",
"NotAfter": "Feb 13 23:59:59 2024 GMT",
"Subject": "C = US, ST = California, L = Los Angeles, O = Internet\C2\A0Corporation\C2\A0for\C2\A0Assigned\C2\A0Names\C2\A0and\C2\A0Numbers, CN = www.example.org",
"Email": "",
"Serial": "0C1FCB184518C7E3866741236D6B73F1",
"Fingerprint": "F2:AA:D7:3D:32:68:3B:71:6D:2A:7D:61:B5:1C:6D:57:64:AB:38:99",
"Version": "3 (0x2)",
"SignatureAlgorithm": "sha256WithRSAEncryption",
"PublicKeyAlgorithm": "rsaEncryption",
"AlternativeName": "DNS:www.example.org, DNS:example.net, DNS:example.edu, DNS:example.com, DNS:example.org, DNS:www.example.com, DNS:www.example.edu, DNS:www.example.net",
"DaysToExpire": "64"
}]
```

Теперь с помощью параметра `UserParameter` нужно разрешить запуск пользовательского скрипта агентом Zabbix:

```shell
vi /etc/zabbix/zabbix_agentd.d/get-domain-certificate.conf
```

Добавить строку:

```ini
UserParameter=get.domain.certificate[*],/usr/lib/zabbix/externalscripts/get-domain-certificate.sh "$1" "$2" "$3"
```

Перезапустить агента:

```shell
systemctl restart zabbix-agent
```

Импортировать шаблон `Additional Template Module Domain Certificate`:
