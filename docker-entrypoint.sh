#!/bin/bash

data=${1}
result=${2}
ts=${3:-$(date +%s)}
job=${4:-standard}

RESULT_ROOT='/realpixel/data'
mkdir -p ${RESULT_ROOT}

echo "[REALPIXEL] start ${job} realpixel job for ${data}"
service filebeat start &&
echo "[REALPIXEL] use: coco.names yolov3-tiny.cfg yolov3-tiny.weights, for: ${data} started at ${ts}, result at: ${RESULT_ROOT}/${result}" &&
./uselib runtime/${job}.names runtime/${job}.cfg runtime/${job}.weights ${data} ${ts} 2>> ${RESULT_ROOT}/${result}.error 1>> ${RESULT_ROOT}/${result} &&
echo "[REALPIXEL] finish ${job} realpixel job for ${data}"
