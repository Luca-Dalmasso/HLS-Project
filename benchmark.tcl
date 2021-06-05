#!/usr/bin/tclsh

source ./tcl_scripts/setenv.tcl

#testing for RTL library 2
read_library ./data/RTL_libraries/RTL_lib_2.txt
#testing for design FIR
read_design ./data/DFGs/fir.dot

#sourcing LIST scheduling 
source ./tcl_scripts/scheduling/list_mlac_contest.tcl
#sourcing MAIN script
source ./contest2.tcl
#ouput file for scheduled DFG
#set output_dot ./data/out/contest/testcontest2.dot
#set max_area 120
#
#get_total_scheduling $max_area  $output_dot

#TEST 2, matmul_dfg__3
remove_design
read_design ./data/DFGs/matmul_dfg__3.dot
set output_dot ./data/out/contest/testcontest2_matmul.dot
set max_area 230

get_total_scheduling $max_area  $output_dot


