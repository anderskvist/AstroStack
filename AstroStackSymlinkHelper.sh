#!/bin/sh

FIRST=${1}
LAST=${2}

START=$(basename ${FIRST}|awk -F '[_.]' '{print $2}')
END=$(basename ${LAST}|awk -F '[_.]' '{print $2}')

DIR=$(dirname ${FIRST})
for I in $(seq -w ${START} ${END}); do
    ln -s  ${DIR}/IMG_${I}.JPG .
done
