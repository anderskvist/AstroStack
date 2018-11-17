#!/bin/bash -xe

function cleanUp () {
    echo -n "Cleaning up..."
    echo "done"
    
}

TS_START=$(date +%s)

trap cleanUp EXIT

# stack bias frames
if [ ! -f bias.jpg ]; then
    convert -monitor bias/*.JPG -evaluate-sequence median bias.jpg
fi

# stack black frames
if [ ! -f black.jpg ]; then
    convert -monitor black/*.JPG -evaluate-sequence median black.jpg
fi

# subtract bias from flat frames, stack, convert to grayscale and stretch to 5% (estimated and looks okay)
if [ ! -f flat-bias.jpg ]; then
    for R in flat/*.JPG; do
	F=$(basename ${R} .JPG)
	if [ ! -f flat/flat-bias_${F}.jpg ]; then
	    composite -monitor flat/${F}.JPG bias.jpg -compose minus flat/flat-bias_${F}.jpg
	fi
    done
    convert -monitor flat/flat-bias_*.jpg -evaluate-sequence median -type Grayscale -linear-stretch 0x5% flat-bias.jpg
fi


# subtract black from light and divide by flat-bias
for R in light/*.JPG; do
    F=$(basename ${R} .JPG)
    if [ ! -f light/light-black_flat-bias_${F}.jpg ]; then
	composite -monitor light/${F}.JPG black.jpg -compose minus light/light-black_${F}.jpg
	composite -monitor light/light-black_${F}.jpg -compose divide flat-bias.jpg light/light-black_flat-bias_${F}.jpg
    fi
done

# align all photos to the center photo (to hopefully have equal movement on each side)
NUM=$(ls -1 light/light-black_flat-bias_*.jpg|wc -l)
MED=$(ls -1 light/light-black_flat-bias_*.jpg|sort|head -n $((${NUM}/2))|tail -n 1)
mkdir -p temp
COUNT=1000
for L in light/light-black_flat-bias*.jpg; do
    if [ ! -f temp/${COUNT}_0001.tif ]; then
	align_image_stack -v -a temp/${COUNT}_ ${MED} ${L} || echo
	rm -f temp/${COUNT}_0000.tif
    fi
    COUNT=$((${COUNT}+1))
done

# perform aligning of photos in groups of sqrt(num total) - to avoid running out of memory
NUM=$(ls -1 temp/*_0001.tif|wc -l)
AMOUNT=$(echo "sqrt(${NUM})"|bc)
I=1
while [ $((${I}*${AMOUNT})) -lt ${NUM} ]; do
    FILES=$(ls -1 temp/*_0001.tif|tail -n $((${I}*${AMOUNT}))|head -n ${AMOUNT})
    convert ${FILES} -monitor -evaluate-sequence median temp/temp-${I}.jpg
    I=$((${I}+1))
done
convert temp/temp-*.jpg -monitor -evaluate-sequence median final.jpg

TS_END=$(date +%s)

echo "Process finished in $(((${TS_END}-${TS_START})/60)) minutes"
