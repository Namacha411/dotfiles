#!/usr/bin/env bash
# Claude Code status line script
# Displays: model name | context usage % | total session tokens

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  ctx_str="CTX: ${used_int}% used"
else
  ctx_str="CTX: --"
fi

total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
total_tokens=$((total_in + total_out))

if [ "$total_tokens" -gt 0 ]; then
  plan_str="Tokens: ${total_tokens}"
else
  plan_str="Tokens: 0"
fi

printf "\033[2m%s | %s | %s\033[0m" "$model" "$ctx_str" "$plan_str"
