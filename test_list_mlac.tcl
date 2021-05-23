#!/usr/bin/tclsh
source ./tcl_scripts/setenv.tcl
read_design ./data/DFGs/fir.dot
read_library ./data/RTL_libraries/RTL_lib_2.txt
source ./tcl_scripts/scheduling/list_mlac_contest.tcl

set input_bounds {{L0 1} {L4 1} {L10 1} {L13 1}}
set lm_result [list_mlac $input_bounds]
set start_time_list [lindex $lm_result 0]

puts "NODE, START-TIME"
foreach item $start_time_list {
	puts "[get_attribute [lindex $item 0] label], [lindex $item 1]"
}

print_dfg ./data/out/contest/testarf2.dot
print_scheduled_dfg $start_time_list ./data/out/contest/testarf2.dot

