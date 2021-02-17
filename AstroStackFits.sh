#!/bin/bash -ex

. $(dirname ${0})/fits_demosaic.sh

# BIAS
if [ ! -f bias.fits ]; then
	for F in bias/*.cr2; do dcraw -t 0 -a -W -D -6 ${F}; done
	for F in bias/*.pgm; do convert ${F} ${F}.fits; rm ${F}; done
	convert -quiet bias/*.fits -monitor -evaluate-sequence median bias.fits
fi

# DARK
if [ ! -f dark.fits ]; then
	for F in dark/*.cr2; do dcraw -t 0 -a -W -D -6 ${F}; done
	for F in dark/*.pgm; do convert ${F} ${F}.fits; rm ${F}; done
	convert -quiet dark/*.fits -monitor -evaluate-sequence median dark.fits
fi

# FLAT
if [ ! -f flat-bias.fits ]; then
	for F in flat/*.CR2; do dcraw -t 0 -a -W -D -6 ${F}; done
	for F in flat/*.pgm; do convert ${F} ${F}.fits; rm ${F}; done
	for F in flat/*.fits; do composite -monitor ${F} bias.fits -compose minus ${F}-bias.fits; rm -f ${F}; done
	convert -quiet flat/*-bias.fits -monitor -evaluate-sequence median -type Grayscale -linear-stretch 0x5% flat-bias.fits
fi

# LIGHT
for F in light/*.cr2; do dcraw -t 0 -a -W -D -6 ${F}; done
for F in light/*.pgm; do convert ${F} ${F}.fits; rm ${F}; done
for F in light/*.fits; do composite -monitor ${F} dark.fits -compose minus ${F}-dark.fits; rm ${F}; done
for F in light/*-dark.fits; do composite -monitor ${F} -compose divide flat-bias.fits ${F}-flat-bias.fits; rm ${F}; done
for F in light/*-dark.fits-flat-bias.fits; do demosaic ${F} ${F}-done.fits; rm ${F}; done
