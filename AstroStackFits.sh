#!/bin/bash -e

function bail () {
	echo ${*}
	exit 1
}

command -v dcraw > /dev/null || bail "Missing dcraw"
command -v convert > /dev/null || bail "Missing ImageMagick convert"
command -v composite > /dev/null || bail "Missing ImageMagick composite"
command -v identify > /dev/null || bail "Missing ImageMagick identify"

. $(dirname ${0})/fits_demosaic.sh

DCRAW="dcraw -t 0 -a -W -D -6 -c"

# BIAS
if [ ! -f bias.fits ]; then
	for F in bias/*.cr2; do
		FILENAME=$(basename ${F} .cr2)
		${DCRAW} ${F} | convert /dev/stdin bias/${FILENAME}.fits
	done
	convert -quiet bias/*.fits -monitor -evaluate-sequence median bias.fits
fi

# DARK
if [ ! -f dark.fits ]; then
	for F in dark/*.cr2; do
		FILENAME=$(basename ${F} .cr2)
		${DCRAW} ${F} | convert /dev/stdin dark/${FILENAME}.fits
	done
	convert -quiet dark/*.fits -monitor -evaluate-sequence median dark.fits
fi

# FLAT
if [ ! -f flat-bias.fits ]; then
	for F in flat/*.CR2; do
		FILENAME=$(basename ${F} .CR2)
		${DCRAW} ${F} | convert /dev/stdin flat/${FILENAME}.fits
		composite -monitor flat/${FILENAME}.fits bias.fits -compose minus flat/${FILENAME}-bias.fits
	done
	convert -quiet flat/*-bias.fits -monitor -evaluate-sequence median -type Grayscale -linear-stretch 0x5% flat-bias.fits
fi

# LIGHT
for F in light/*.cr2; do
	FILENAME=$(basename ${F} .cr2)
	${DCRAW} ${F} | composite -monitor /dev/stdin dark.fits -compose minus light/${FILENAME}-dark.fits
	composite -monitor light/${FILENAME}-dark.fits -compose divide flat-bias.fits light/${FILENAME}-dark-flat-bias.fits
	demosaic light/${FILENAME}-dark-flat-bias.fits ${FILENAME}-done.fits
done
