#!/bin/bash
set -e
iverilog -g2012 -o speck_sim speck32_64.sv tb_speck32_64.sv
vvp speck_sim
