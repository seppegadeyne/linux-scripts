#!/bin/bash

directory=/home
email=seppe@fushia.be
phone="+32495783990"
scan=`/usr/local/maldetect/maldet -u -d -a $directory | tail -n 2 | head -n 1 | cut -d , -f 2 | grep -oE "[[:digit:]]"`

if [ $scan -ne 0 ]; then
        message_scan="Malware (${scan}) found on `uname -n`"
        echo $message_scan | mail -s "Malware found" $email
        curl -X POST https://textbelt.com/text \
                --data-urlencode phone="${phone}" \
                --data-urlencode message="${message_scan}" \
                -d key=7f38d58d46dc157881d892aa5489e0e416d62331wEHCKusY15hEfcG1VtYDccaoT
fi
