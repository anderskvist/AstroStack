#!/bin/bash -e

function bail () {
	echo ${*}
	exit 1
}

command -v dcraw > /dev/null || bail "Missing dcraw"
command -v convert > /dev/null || bail "Missing ImageMagick convert"
command -v composite > /dev/null || bail "Missing ImageMagick composite"

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
for F in light/*.cr2; do dcraw -t 0 -a -W -D -6 ${F}; done
for F in light/*.pgm; do convert ${F} ${F}.fits; rm ${F}; done
for F in light/*.fits; do composite -monitor ${F} dark.fits -compose minus ${F}-dark.fits; rm ${F}; done
for F in light/*-dark.fits; do composite -monitor ${F} -compose divide flat-bias.fits ${F}-flat-bias.fits; rm ${F}; done
for F in light/*-dark.fits-flat-bias.fits; do demosaic ${F} ${F}-done.fits; rm ${F}; done
