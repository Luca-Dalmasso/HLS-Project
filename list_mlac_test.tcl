#!/bin/tclsh
#remove_lib
#remove_design
#read_lib ../data/RTL_libraries/RTL_lib_1.txt
#read_design ../data/DFGs/myEx2.dot
source tcl_scripts/scheduling/list_mlac_contest.tcl
#set params {{MUL 1} {ADD 1} {LOD 1} {STR 1}}
set params {{L4 1 MUL} {L1 1 ADD} {L11 1 LOD} {L15 1 STR}}
set lm_result [list_mlac $params [get_sorted_nodes]]
set start_time_list [lindex $lm_result 0]
set latency [lindex $lm_result 1]
foreach pair $start_time_list {
	set node_id [lindex $pair 0]
	set start_time [lindex $pair 1]
	puts "Node: $node_id starts @ $start_time"
}
puts "Latency: $latency"
