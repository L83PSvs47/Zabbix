---
title: '202312111522'
author: 
description: Проверка IP в DNSBL по имени домена (берутся A или MX записи)
created: 2023-12-11 15:22
updated: 2023-12-12 09:45
links: ['[The Spamhaus Project - Frequently Asked Questions (FAQ)](https://www.spamhaus.org/faq/section/DNSBL%20Usage#365)', '[hluaces/zabbix-local-dnsbl-check: A Zabbix template to monitor the health of every IP address for a mail server on several DNSBL services. (github.com)](https://github.com/hluaces/zabbix-local-dnsbl-check)']
tags: [zabbix, linux, bash, script, dnsbl, monitoring, template]
aliases: []
---

Для получения данных о сроках действия сертификата домена будет использоваться небольшой bash скрипт. Для его работы на сервере Zabbix (или Zabbix прокси) потребуется `bind-utils`.

Установить `bind-utils`:

```shell
dnf install bind-utils -y
```

Проверьте в конфигурационном файле `/etc/zabbix/zabbix_server.conf` (если будет запускаться на сервере Zabbix) или `/etc/zabbix/zabbix_proxy.conf` (если будет запускаться на Zabbix прокси) путь к каталогу для внешних скриптов. По умолчанию это `ExternalScripts=/usr/lib/zabbix/externalscripts` (нужно раскомментировать строку или указать новый путь).

Создайте в этом каталоге файл `get-domain-dnsbl.sh`:

```shell
vi /usr/lib/zabbix/externalscripts/get-domain-dnsbl.sh
```

Добавьте в созданный файл код:

```shell
#!/bin/bash -e

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

case $TYPE in
"mx")
    HOSTIPLIST=$(dig +short $(dig +short MX $DOMAIN))
    ;;
*)
    HOSTIPLIST=$(dig +short $DOMAIN)
    ;;
esac

for HOSTIP in $HOSTIPLIST; do
    REVIP=$(sed -r 's/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/\4.\3.\2.\1/' <<<$HOSTIP)
    if [[ $(dig +short $REVIP.$DNSBL) ]]; then
        ((COUNT += 1))
    fi
done

echo "[{"
echo "\"DNSBL\": \"$COUNT\","
echo "\"IPLIST\": \"$HOSTIPLIST\""
echo "}]"
```

Разрешить запуск скрипта:

```shell
chmod +x /usr/lib/zabbix/externalscripts/get-domain-dnsbl.sh
```

Проверить работу скрипта:

```shell
/usr/lib/zabbix/externalscripts/get-domain-dnsbl.sh example.com zen.spamhaus.org
```

```info
[{
"DNSBL": "0",
"IPLIST": "93.184.216.34"
}]
```

Теперь с помощью параметра `UserParameter` нужно разрешить запуск пользовательского скрипта агентом Zabbix:

```shell
vi /etc/zabbix/zabbix_agentd.d/get-domain-dnsbl.conf
```

Добавить строку:

```ini
UserParameter=get.domain.dnsbl[*],/usr/lib/zabbix/externalscripts/get-domain-dnsbl.sh "$1" "$2" "$3"
```

Перезапустить агента:

```shell
systemctl restart zabbix-agent
```

Импортировать шаблон `Additional Template Module Domain Certificate`:
