#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
profile="${1:-smoke}"
case "$profile" in smoke|load|stress) ;; *) echo 'Use smoke, load or stress'; exit 2;; esac
run_dir="results/${profile}-$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$run_dir"
"${JMETER_HOME:?Set JMETER_HOME to Apache JMeter 5.6.3}"/bin/jmeter -n -t performance/workflow.jmx -q "performance/$profile.properties" -Jhost="${API_HOST:-127.0.0.1}" -Jport="${API_PORT:-8080}" -JinfluxUrl="${INFLUX_URL:-http://127.0.0.1:8086/write?db=jmeter}" -l "$run_dir/samples.jtl" -j "$run_dir/jmeter.log" -e -o "$run_dir/html"
python3 performance/check_slo.py "$run_dir/samples.jtl" "${P95_BUDGET_MS:-1000}" | tee "$run_dir/slo.json"
printf 'Report: %s/html/index.html\n' "$run_dir"
