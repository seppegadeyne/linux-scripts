#!/bin/bash

INDEX_PAYLOAD=$(printf "tom-de-schutter" | xxd -ps)\
 && DATA_PAYLOAD=$(printf "Wanneer terrasje?" | xxd -ps)\
 && PAYLOAD=$(echo -e "{\"payload\": {\"type\": 2,\"index\": \"$INDEX_PAYLOAD\", \"data\": \"$DATA_PAYLOAD\"}}")\
 && curl --request POST --header "Content-Type: application/json" --data "$PAYLOAD" --url https://api.lb-0.testnet.chrysalis2.com/api/v1/messages 
