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

## Testing

Testing with a Ublox NEO-M8N GPS module, and the Sipeed tang-nano FPGA board.
The reference tested is the 24MHz crystal on the tang-nano board no specification found on the crystal.
With the system on the desk running the counts found seems stable to +-1 count.
- count between 24 001 015 and 24 001 016 with a resulting ppb error of 42 291ppb and 42 333ppb
- This shows quite stable measurement.