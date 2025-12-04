#!/bin/bash

INPUT_FILE="ips.txt"
OUTPUT_FILE="result.txt"

echo "Testing IP latency..."
rm -f $OUTPUT_FILE
touch $OUTPUT_FILE

TMP_FILE=$(mktemp)

# 对每个 IP 进行测速
while read -r ip; do
    [ -z "$ip" ] && continue

    start=$(date +%s%3N)
    curl -o /dev/null -s --max-time 3 "http://$ip/generate_204"
    status=$?
    end=$(date +%s%3N)

    if [ $status -eq 0 ]; then
        latency=$((end - start))
        echo "$latency ms - $ip"
        echo "$latency $ip" >> $TMP_FILE
    else
        echo "timeout - $ip"
    fi
done < "$INPUT_FILE"

# 排序并取前10
sort -n $TMP_FILE | head -n 10 | awk '{print $2}' > $OUTPUT_FILE

echo "Top 10 IPs saved to $OUTPUT_FILE"
cat $OUTPUT_FILE

rm $TMP_FILE
