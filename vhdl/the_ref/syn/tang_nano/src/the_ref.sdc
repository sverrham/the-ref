//Copyright (C)2014-2020 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.3.01 Beta
//Created Time: 2020-05-27 20:53:24
create_clock -name clk_i -period 41.667 -waveform {0 20.834} [get_ports {clk_i}]
report_timing -setup -from_clock [get_clocks {clk_i}] -max_paths 25 -max_common_paths 1
