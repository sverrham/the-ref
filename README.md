# the-ref

## GPS pps base reference system

The goal is to have a simple system that generates a 10MHz reference clock that is accurate, how accurate is yet to be seen.

## Design

GPS -> PPS -> FPGA -> DAC -> VCXO -> 10MHz ref

The FPGA implements a simple counter based on the clock to be calibrated, each pps the offset is reported for status and regulation of the clock to achieve good lock.

## Calculations

with a measurement period of 1s when using the gps pps (assuming the pps is truth) and a 10MHz reference we should have 1 clock cycles of the 10MHz of uncertainty, this is from the pps signal coming some time before the clock when starting to count and same at next pps. Uncertainty of 1 clock cycle should result in 1 count wrong in 10 000 000 which is equal to 0.1ppm or 100ppb.

## GPS PPS

Need to figure out how accurate the pps actually is.