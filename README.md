# the-ref

## GPS pps base reference system

The goal is to have a simple system that generates a 10MHz reference clock that is accurate, how accurate is yet to be seen.

## Design

GPS -> PPS -> FPGA -> DAC -> VCXO -> 10MHz ref

The FPGA implements a simple counter based on the clock to be calibrated, each pps the offset is reported for status and regulation of the clock to achieve good lock.

