#!/bin/bash

INPUT_FILE="ips.txt"
OUTPUT_FILE="result.txt"

echo "Starting optimized latency test..."

rm -f $OUTPUT_FILE
touch $OUTPUT_FILE

TMP_FILE=$(mktemp)

# 测试单个 IP 的函数
test_ip() {
    line="$1"

    # 分离 IP 和地区（地区不再使用）
    ip=$(echo "$line" | cut -d'#' -f1 | tr -d ' ')

    # 跳过空行
    [ -z "$ip" ] && return

    # 尝试 HTTP 测速
    start=$(date +%s%3N)
    curl -o /dev/null -s --max-time 3 "http://$ip/generate_204"
    status=$?
    end=$(date +%s%3N)

    # 如果失败改用 HTTPS 再测一次
    if [ $status -ne 0 ]; then
        start=$(date +%s%3N)
        curl -o /dev/null -s --max-time 3 "https://$ip/generate_204"
        status=$?
        end=$(date +%s%3N)
    fi

    # 失败丢弃
    if [ $status -ne 0 ]; then
        echo "timeout - $ip"
        return
    fi

    latency=$((end - start))

    echo "$latency ms - $ip"
    echo "$latency $ip" >> $TMP_FILE
}

export -f test_ip

# 并发执行，提升速度（20个并发）
cat "$INPUT_FILE" | xargs -I {} -P 20 bash -c "test_ip '{}'"

echo "Sorting results..."

# 取最快 10 个，只输出 IP，不带地区
sort -n $TMP_FILE | head -n 10 | awk '{print $2}' > $OUTPUT_FILE

echo
echo "=== Top 10 IPs (pure IP) ==="
cat $OUTPUT_FILE

rm $TMP_FILE
