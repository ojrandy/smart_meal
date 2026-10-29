#!/usr/bin/env bash
# Recomputes the WFP-based rows of docs/reference/ingredient-prices-cm.csv.
#
# Downloads WFP's Cameroon retail food prices from HDX (CC BY-IGO), keeps the
# southern urban markets, and prints the median price per commodity over the
# 12 months before the newest observation. Copy changed medians into the
# price list by hand, following docs/reference/ingredient-prices-cm.md.
#
# Usage: tool/wfp_prices.sh [workdir]   (default: a fresh temp directory)
set -euo pipefail

URL='https://data.humdata.org/dataset/f6ed9f06-36b9-43b2-97f3-fc0b8e16d155/resource/9deec824-1e42-4a91-b704-b73fd250ec5a/download/wfp_food_prices_cmr.csv'
# Cities where most users shop. Rural producer markets sell well below city
# prices, and northern markets have a different supply, so both are left out.
MARKETS='^(Yaoundé-Mfoundi|Douala-Marché Central|Buea|Limbé|Kumba|Bamenda|Mamfé|Tiko|Mutengene|Muea)$'

dir="${1:-$(mktemp -d)}"
mkdir -p "$dir"
csv="$dir/wfp_food_prices_cmr.csv"
curl -fsSL --retry 3 -A 'Mozilla/5.0' "$URL" -o "$csv"

newest=$(awk -F, 'NR > 2 && $1 > max { max = $1 } END { print max }' "$csv")
# 12-month window ending at the newest observation.
from="$(( ${newest:0:4} - 1 ))-$(( 10#${newest:5:2} + 1 ))-01"
[[ ${newest:5:2} == 12 ]] && from="${newest:0:4}-01-01"
[[ ${#from} -eq 9 ]] && from="${from:0:5}0${from:5}"

echo "WFP Cameroon retail prices, southern urban markets, $from .. $newest"
awk -F, -v from="$from" -v markets="$MARKETS" '
  NR > 2 && $1 >= from && $13 == "Retail" && $4 ~ markets && $9 !~ /Wage/ {
    print $9 " [" $11 "]\t" $15 "\t" $1
  }' "$csv" |
  sort -t$'\t' -k1,1 -k2,2n |
  awk -F'\t' '
    { key = $1; prices[key] = prices[key] " " $2; n[key]++; if ($3 > last[key]) last[key] = $3 }
    END {
      for (key in n) {
        split(substr(prices[key], 2), p, " ")
        c = n[key]
        median = (c % 2) ? p[(c + 1) / 2] : (p[c / 2] + p[c / 2 + 1]) / 2
        printf "%-30s median=%-6.0f p25=%-6.0f p75=%-6.0f n=%-3d last=%s\n",
          key, median, p[int(c * 0.25) + 1], p[int(c * 0.75) + 1], c, last[key]
      }
    }' | sort
