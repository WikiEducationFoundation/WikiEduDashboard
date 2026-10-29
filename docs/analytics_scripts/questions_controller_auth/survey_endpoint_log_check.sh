#!/bin/bash
# Read-only. Run as root on the Wiki Ed production server, from the repo root:
#   ssh dashboard.wikiedu.org 'sudo bash -s' < docs/analytics_scripts/questions_controller_auth/survey_endpoint_log_check.sh
# Summarizes requests to the three QuestionsController endpoints fixed in
# 5619bdbe2 (GHSA-3435-9pw5-6pxr), from Apache access logs and the Rails
# request log that Passenger writes to Apache's error logs.
# An optional first argument overrides the log directory (default /var/log/apache2).
LOGDIR=${1:-/var/log/apache2}

# Print the given files' contents, oldest file first, decompressing as needed.
cat_oldest_first() {
  find "$LOGDIR" -name "$1" -printf '%T@ %p\n' | sort -n | cut -d' ' -f2- |
    xargs -r zcat -f
}

echo "== HTTPS access logging config"
ls /etc/apache2/conf-enabled/ 2>/dev/null | grep -i access || echo "(no access-log conf enabled)"
cat /etc/logrotate.d/apache2 2>/dev/null

echo
echo "== Log files (mtime, bytes, path)"
find "$LOGDIR" \( -name '*access*' -o -name 'error.log*' \) -printf '%TY-%Tm-%Td %s %p\n' | sort

echo
echo "== Earliest entry in each access log"
for name in 'other_vhosts_access.log*' 'access.log*'; do
  echo "$name: $(cat_oldest_first "$name" 2>/dev/null | head -1)"
done

echo
echo "== Access-log hits: ip method endpoint status hits distinct_ids max_bytes first last admin_ip"
cat_oldest_first '*access*' | awk '
  {
    for (i = 6; i <= NF; i++) if ($i ~ /^"(GET|PUT|POST|HEAD|PATCH|DELETE|OPTIONS)$/) break
    if (i > NF) next
    ip = $(i - 5); t = substr($(i - 2), 2); m = substr($i, 2)
    path = $(i + 1); st = $(i + 3); b = $(i + 4) + 0
    # A 200 on a survey results page means an admin session from this IP.
    if (path ~ /^\/survey\/results\/[0-9]+/ && st == 200) admin[ip] = 1
    if (path ~ /^\/survey\/question\/results\//) ep = "csv"
    else if (path ~ /^\/surveys\/question_position/) ep = "reorder"
    else if (path ~ /^\/surveys\/question_group_question\//) ep = "json"
    else next
    id = path; sub(/^.*\//, "", id); sub(/[.?].*$/, "", id)
    k = ip " " m " " ep " " st
    if (!(k in n)) first[k] = t
    n[k]++; last[k] = t; if (b > max[k]) max[k] = b
    if (!((k, id) in seen)) { seen[k, id] = 1; ids[k]++ }
  }
  END {
    for (k in n) {
      split(k, a, " ")
      print k, n[k], ids[k], max[k] + 0, first[k], last[k], (a[1] in admin ? "yes" : "-")
    }
  }' | sort

echo
echo "== Earliest Rails log line"
cat_oldest_first 'error.log*' 2>/dev/null | grep -a -m1 -E '[IWEF], \['

echo
echo "== Rails log hits: ip method endpoint hits distinct_ids first last"
cat_oldest_first 'error.log*' |
  grep -a -E 'Started (GET|PUT) "/(survey/question/results|surveys/question_position|surveys/question_group_question)' |
  awk '
    {
      match($0, /Started [A-Z]+ "[^"]*" for [^ ]+ at [^ ]+ [^ ]+/)
      split(substr($0, RSTART, RLENGTH), f, " ")
      m = f[2]; path = f[3]; gsub(/"/, "", path); ip = f[5]; t = f[7] "T" f[8]
      if (path ~ /question\/results/) ep = "csv"
      else if (path ~ /question_position/) ep = "reorder"
      else ep = "json"
      id = path; sub(/^.*\//, "", id); sub(/[.?].*$/, "", id)
      k = ip " " m " " ep
      if (!(k in n)) first[k] = t
      n[k]++; last[k] = t
      if (!((k, id) in seen)) { seen[k, id] = 1; ids[k]++ }
    }
    END { for (k in n) print k, n[k], ids[k], first[k], last[k] }' | sort
