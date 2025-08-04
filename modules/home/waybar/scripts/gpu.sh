#!/bin/bash

usage_temp=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits | head -n1)
usage=$(echo $usage_temp | cut -d',' -f1 | xargs)
temp=$(echo $usage_temp | cut -d',' -f2 | xargs)

echo "{\"text\": \" ${usage}% ${temp}°C\", \"tooltip\": \"GPU Usage: ${usage}%\nTemp: ${temp}°C\"}"
