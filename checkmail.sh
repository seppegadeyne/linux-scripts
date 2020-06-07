#!/bin/bash

phone="+32495783990"
mailq_count=`/usr/bin/mailq | /usr/bin/tail -n 1 | /usr/bin/gawk '{print $5}'`
mailq_count=`expr $mailq_count + 0`

if [ $mailq_count -gt 50 ]; then
	message_scan="Mailqueue (${mailq_count}) on server `uname -n` needs attention"
        curl -X POST https://textbelt.com/text \
                --data-urlencode phone="${phone}" \
                --data-urlencode message="${message_scan}" \
                -d key=7f38d58d46dc157881d892aa5489e0e416d62331wEHCKusY15hEfcG1VtYDccaoT
	sudo /etc/init.d/postfix stop
fi

