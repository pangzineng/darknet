#!/bin/bash

data=${1}
ts=${2:-$(date +%s)}
job=${3:-tiny}

INPUT_ROOT='/realpixel/input'
OUTPUT_ROOT='/realpixel/output'
mkdir -p ${INPUT_ROOT}
mkdir -p ${OUTPUT_ROOT}

echo "[REALPIXEL] start ${job} realpixel job for ${data}"
service filebeat start &&
echo "[REALPIXEL] use: coco.names yolov3-tiny.cfg yolov3-tiny.weights, for: ${data} started at ${ts}, result at: ${OUTPUT_ROOT}/${data}.log" &&
./uselib runtime/${job}.names runtime/${job}.cfg runtime/${job}.weights ${INPUT_ROOT}/${data} ${ts} 2>> ${OUTPUT_ROOT}/${data}.log.error 1>> ${OUTPUT_ROOT}/${data}.log &&
echo "[REALPIXEL] finish ${job} realpixel job for ${data}"
