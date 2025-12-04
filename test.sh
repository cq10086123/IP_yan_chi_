#!/bin/bash

INPUT_FILE="ips.txt"
OUTPUT_FILE="result.txt"

echo "Starting google 204 latency test..."

rm -f $OUTPUT_FILE
touch $OUTPUT_FILE

TMP_FILE=$(mktemp)

test_ip() {
    line="$1"

    # 提取 IP（去掉 #地区）
    ip=$(echo "$line" | cut -d'#' -f1 | tr -d ' ')
    [ -z "$ip" ] && return

    # 用这个 IP 作为出口测试 Google 延迟
    start=$(date +%s%3N)
    curl -o /dev/null -s --interface "$ip" --max-time 5 "https://www.gstatic.com/generate_204"
    status=$?
    end=$(date +%s%3N)

    if [ $status -ne 0 ]; then
        echo "timeout - $ip"
        return
    fi

    latency=$((end - start))

    echo "$latency ms - $ip"
    echo "$latency $ip" >> $TMP_FILE
}

export -f test_ip

# 并发测试
cat "$INPUT_FILE" | xargs -I {} -P 20 bash -c "test_ip '{}'"

echo "Sorting results..."

sort -n $TMP_FILE | head -n 10 | awk '{print $2}' > $OUTPUT_FILE

echo
echo "=== Top 10 Google 204 Latency (pure IP) ==="
cat $OUTPUT_FILE

rm $TMP_FILE
