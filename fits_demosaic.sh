function demosaic () {
    INFILE=${1}
    OUTFILE=${2}

    W=$(identify -format "%w" ${INFILE} 2> /dev/null)
    H=$(identify -format "%h" ${INFILE} 2> /dev/null)
    RESIZE="-resize ${W}x${H}"
    sFILT="-filter Lanczos"

    MULT_R="-evaluate Multiply 1"
    MULT_G0="-evaluate Multiply 1"
    MULT_G1="-evaluate Multiply 1"
    MULT_B="-evaluate Multiply 1"

    convert \
        ${INFILE} \
        -monitor \
        -evaluate Multiply 1 \
        -filter Lanczos \
        \( -clone 0 -define sample:offset=25 -sample 50% ${MULT_R} \
        ${RESIZE} ${dm_WR_R} \) \
        \( -clone 0 \
        \( -clone 0 -define sample:offset=75x25 -sample 50% ${MULT_G0} \
        ${RESIZE} ${dm_WR_G0} \) \
        \( -clone 0 -define sample:offset=25x75 -sample 50% ${MULT_G1} \
        ${RESIZE} ${dm_WR_G1} \) \
        -delete 0 \
        -evaluate-sequence mean \
        \) \
        \( -clone 0 -define sample:offset=75 -sample 50% ${MULT_B} \
        ${RESIZE} ${dm_WR_B} \) \
        -delete 0 \
        -combine \
        -gamma 2.2 \
        ${OUTFILE}
}
