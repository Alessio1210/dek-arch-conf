#!/usr/bin/env bash

set -o pipefail

url='https://api.coingecko.com/api/v3/simple/price?ids=solana&vs_currencies=eur'
if response=$(curl --fail --silent --show-error --max-time 10 "$url" 2>/dev/null) &&
   price=$(jq -er '.solana.eur | select(type == "number" and . > 0)' <<< "$response" 2>/dev/null); then
    LC_NUMERIC=C printf '1 SOL = %.2f€\n' "$price"
else
    printf '1 SOL = unavailable\n'
fi
