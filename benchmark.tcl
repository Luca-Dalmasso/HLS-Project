#!/usr/bin/tclsh

source ./tcl_scripts/setenv.tcl
source ./tcl_scripts/sanity_topological_sort.tcl


#testing for RTL library 2
read_library ./data/RTL_libraries/RTL_lib_2.txt
#sourcing MAIN script
read_design ./data/DFGs/fir.dot
source ./contest2.tcl


#TEST 3, matmul_dfg__3
remove_design
read_design ./data/DFGs/matmul_dfg__3.dot
set max_area 500
puts "\n\nMATMUL\n\n"
set ret [get_total_scheduling $max_area]
puts "[lindex $ret 0]"
#sanity checks
set nodes_scheduled ""
foreach item [lindex $ret 0] {
	lappend nodes_scheduled [lindex $item 0]
}
puts "[sanity $nodes_scheduled]"
set levels [lindex [get_levels] 0]
puts "[sanity $levels]"
print_dfg ./data/out/contest/test_matmul_dfg__3.dot
print_scheduled_dfg [lindex $ret 0] ./data/out/contest/test_matmul_dfg__3.dot
#TEST 1, FIR
remove_design
read_design ./data/DFGs/fir.dot
set max_area 200
puts "\n\nFIR\n\n"
set ret [get_total_scheduling $max_area]
puts "[lindex $ret 0]"
#sanity checks
set nodes_scheduled ""
foreach item [lindex $ret 0] {
	lappend nodes_scheduled [lindex $item 0]
}
puts "[sanity $nodes_scheduled]"
set levels [lindex [get_levels] 0]
puts "[sanity $levels]"
print_dfg ./data/out/contest/test_fir.dot
print_scheduled_dfg [lindex $ret 0] ./data/out/contest/test_fir.dot

#TEST 2, motion_vector
remove_design
read_design ./data/DFGs/motion_vectors_dfg__7.dot
set max_area 500
puts "\n\nMOTION\n\n"
set ret [get_total_scheduling $max_area]
puts "[lindex $ret 0]"

#sanity checks
set nodes_scheduled ""
foreach item [lindex $ret 0] {
	lappend nodes_scheduled [lindex $item 0]
}
puts "[sanity $nodes_scheduled]"
set levels [lindex [get_levels] 0]
puts "[sanity $levels]"
print_dfg ./data/out/contest/test_motion_vectors_dfg__7.dot
print_scheduled_dfg [lindex $ret 0] ./data/out/contest/test_motion_vectors_dfg__7.dot

