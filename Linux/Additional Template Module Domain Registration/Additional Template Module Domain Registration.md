---
title: '202312080941'
author: 
description: Проверка срока истечения домена
created: 2023-12-08 09:41
updated: 2023-12-11 10:04
links: ['[Zabbix — срок действия домена 3 | internet-lab.ru](https://internet-lab.ru/zabbix_domain_expiration3)']
tags: [zabbix, linux, bash, script, domain, expiration, monitoring, template]
aliases: []
---

Для получения данных о сроках делегирования доменов будет использоваться небольшой bash скрипт. Для его работы на сервере Zabbix (или Zabbix прокси) потребуется утилита `whois`.
Установить `whois`:

```shell
dnf install whois -y
```

Проверьте в конфигурационном файле `/etc/zabbix/zabbix_server.conf` (если будет запускаться на сервере Zabbix) или `/etc/zabbix/zabbix_proxy.conf` (если будет запускаться на Zabbix прокси) путь к каталогу для внешних скриптов. По умолчанию это `ExternalScripts=/usr/lib/zabbix/externalscripts` (нужно раскомментировать строку или указать новый путь).

Создайте в этом каталоге файл `get-domain-info.sh`:

```shell
vi /usr/lib/zabbix/externalscripts/get-domain-info.sh
```

Добавьте в созданный файл код:

```shell
#!/bin/bash

# получаем переменные
DOMAIN=$1

if [[ $DOMAIN = "" ]]; then
    echo "[{\"Error\": \"No domain\"}]"
    exit
fi

# получаем имя зоны
ZONE=$(echo $DOMAIN | sed 's/\./ /' | awk '{ print $2 }')

# получаем дату протухания домена
case "$ZONE" in
spb.ru | msk.ru)
    WHOIS=$(whois -h whois.flexireg.net $DOMAIN)
    DATE=$(echo "$WHOIS" | grep -m 1 "Registry Expiry Date:" | awk '{ print $4 }')
    if [[ $DATE != "" ]]; then
        REGISTRAR=$(echo "$WHOIS" | grep -m 1 "Registrar: " | cut -b 12- | sed -e 's/^[ \t]*//')
        CDATE=$(echo "$WHOIS" | grep -m 1 "Creation Date:" | awk '{ print $3 }')
        NSERVER=$(echo "$WHOIS" | grep "Name Server:" | cut -b 13- | xargs)
    fi
    ;;
shop)
    WHOIS=$(whois -h whois.nic.shop $DOMAIN)
    DATE=$(echo "$WHOIS" | grep -m 1 "Registry Expiry Date:" | awk '{ print $4 }')
    if [[ $DATE != "" ]]; then
        REGISTRAR=$(echo "$WHOIS" | grep -m 1 "Registrar: " | cut -b 12- | sed -e 's/^[ \t]*//')
        CDATE=$(echo "$WHOIS" | grep -m 1 "Creation Date:" | awk '{ print $3 }')
        NSERVER=$(echo "$WHOIS" | grep "Name Server:" | cut -b 13- | xargs)
    fi
    ;;
ooo)
    WHOIS=$(whois -h whois.PublicDomainRegistry.com $DOMAIN)
    DATE=$(echo "$WHOIS" | grep -m 1 "Registrar Registration Expiration Date:" | awk '{ print $5 }')
    if [[ $DATE != "" ]]; then
        REGISTRAR=$(echo "$WHOIS" | grep -m 1 "Registrar: " | cut -b 12- | sed -e 's/^[ \t]*//')
        CDATE=$(echo "$WHOIS" | grep -m 1 "Creation Date:" | awk '{ print $3 }')
        NSERVER=$(echo "$WHOIS" | grep "Name Server:" | cut -b 13- | xargs)
    fi
    ;;
tw)
    WHOIS=$(whois $DOMAIN)
    DATE=$(echo "$WHOIS" | grep "Record expires on" | sed 's/Record expires on //' | xargs | sed -e 's/[()]//g')
    if [[ $DATE != "" ]]; then
        REGISTRAR=$(echo "$WHOIS" | grep -m 1 "Registration Service Provider: " | cut -b 32- | sed -e 's/^[ \t]*//')
        CDATE=$(echo "$WHOIS" | grep -m 1 "Record created on" | sed 's/Record created on //' | xargs | sed -e 's/[()]//g')
        NSERVER=$(echo "$WHOIS" | grep -m 1 -A 5 "Domain servers in listed order:" | grep -v "Domain servers in listed order:" | grep -m 1 -B 5 ^$ | grep -v ^$ | xargs)
    fi
    ;;
*)
    # info re org com net ru net.ru org.ru pp.ru рф ...
    WHOIS=$(whois $DOMAIN)
    DATE=$(echo "$WHOIS" | awk '/[Ee]xpir.*[Dd]ate:/ || /[Tt]ill:/ || /expire/ {print $NF; exit;}')
    if [[ $DATE != "" ]]; then
        REGISTRAR=$(echo "$WHOIS" | awk '/[Rr]egistrar:/ {print $0; exit;}' | sed -e 's/^[ \t]*//' | cut -b 12- | xargs)
        CDATE=$(echo "$WHOIS" | awk '/[Cc]reat.*[Dd]ate:/ || /[Cc]reated:/ {print $NF; exit;}')
        NSERVER=$(echo "$WHOIS" | awk '/^[Nn]ame.*[Ss]erver:/ || /nserver:/ {print tolower($NF)}' | xargs)
    fi
    ;;
esac

DIFFDAYS=-1

#если дата валидная
VALIDDATE=$(
    LANG=en_EN TZ=GMT date -d "$DATE" +"%b %d %R:%S %Y %Z" >/dev/null 2>&1
    echo $?
)
if [[ $VALIDDATE == 0 ]]; then
    EXPDATE=$(LANG=en_EN TZ=GMT date -d "$DATE" +"%b %d %R:%S %Y %Z")
    if [[ $EXPDATE != "" ]]; then
        CURRENTDATE=$(LANG=en_EN TZ=GMT date +"%b %d %R:%S %Y %Z")
        DIFFDAYS=$(echo $((($(date -d "$EXPDATE" +"%s") - $(date -d "$CURRENTDATE" +"%s")) / 86400)))
    fi
else
    echo "[{\"Error\": \"Wrong whois response\"}]"
    exit
fi

VALIDDATECREATED=$(
    LANG=en_EN TZ=GMT date -d "$CDATE" +"%b %d %R:%S %Y %Z" >/dev/null 2>&1
    echo $?
)
if [[ $VALIDDATECREATED == 0 ]]; then CREATED=$(LANG=en_EN TZ=GMT date -d "$CDATE" +"%b %d %R:%S %Y %Z"); fi

# вывод данных
echo "[{"
echo "\"Domain\": \"$DOMAIN\","
echo "\"NS\": \"$NSERVER\","
echo "\"Registrar\": \"$REGISTRAR\","
echo "\"Created\": \"$CREATED\","
echo "\"Expired\": \"$EXPDATE\","
echo "\"DaysToExpire\": \"$DIFFDAYS\""
echo "}]"
```

Разрешить запуск скрипта:

```shell
chmod +x /usr/lib/zabbix/externalscripts/get-domain-info.sh
```

Проверить работу скрипта:

```shell
/usr/lib/zabbix/externalscripts/get-domain-info.sh example.com
```

```info
[{
"domain": "example.com",
"ns": "",
"registrar": "RESERVED-Internet Assigned Numbers Authority",
"created": "Aug 14 04:00:00 1995 GMT",
"expdate": "Aug 13 04:00:00 2024 GMT",
"days": "248"
}]
```

Теперь с помощью параметра `UserParameter` нужно разрешить запуск пользовательского скрипта агентом Zabbix:

```shell
vi /etc/zabbix/zabbix_agentd.d/get-domain-info.conf
```

Добавить строку:

```ini
UserParameter=get.domain.info[*],/usr/lib/zabbix/externalscripts/get-domain-info.sh $1
```

Перезапустить агента:

```shell
systemctl restart zabbix-agent
```

Импортировать шаблон `Additional Template Module Domain Registration`:
