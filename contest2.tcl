#!/usr/bin/tclsh

source ./tcl_scripts/setenv.tcl
remove_library
remove_design
read_design ./data/DFGs/fir.dot
read_library ./data/RTL_libraries/RTL_lib_2.txt
source ./tcl_scripts/scheduling/list_mlac_contest.tcl

set fus [list]
set real_fus [list]
set greedy_list [list]
set params [list]
set greedy_list_decreasing_delay [list]
set output_dot ./data/out/contest/testcontest2.dot

#all fus in the library grouped by type of op
foreach fu [get_lib_fus] {
	set op [get_attribute $fu operation]
	set area [get_attribute $fu area]
	set delay [get_attribute $fu delay]
	set idx [lsearch $fus [list $op *]]
	if {$idx>=0} {
		lset fus $idx 1 end+1 [list $fu $area $delay]
	} else {
		lappend fus [list $op [list [list $fu $area $delay]]]
	}
}
#order fus of the same type by increasing area
set i 0
foreach fu $fus {
	lset fus $i 1 [lsort -integer -increasing -index 1 [lindex $fu 1]]
	incr i
}
#puts "all fus: $fus"
#used fus grouped by type of op (internally ordered as before)
foreach node [get_nodes] {
	set op [get_attribute $node operation]
	set idx [lsearch $real_fus [list $op *]]
	if {$idx<0} {
		set idx2 [lsearch $fus [list $op *]]
		if {$idx2<0} {
			puts "error, no fu found to execute $op"
			return
		}
		lappend real_fus [lindex $fus $idx2]
		foreach fu [lindex [lindex $fus $idx2] 1] {
			lappend greedy_list_decreasing_delay [lappend fu $op]
		}

	}
}
#puts "used fus (increasing area ordered): $real_fus"

#cost function #1
set greedy_list_decreasing_delay [lsort -integer -decreasing -index 2 $greedy_list_decreasing_delay]
set greedy_list $greedy_list_decreasing_delay

proc print_greedy {ordered_list} {
	foreach item $ordered_list {
		puts $item
	}
}

puts "executing with"
print_greedy $greedy_list

#update params on new sorting
set area 0
foreach fu $real_fus {
	set op [lindex $fu 0]
	set smallest_fu [lindex [lindex [lindex $fu 1] 0] 0]
	lappend params [list $smallest_fu 1 $op]
	set area [expr {$area + [get_attribute $smallest_fu area]} ]
	#remove from greedy list already scheduled op
	set g_idx [lsearch -index 0 $greedy_list $smallest_fu]
	set greedy_list [lreplace $greedy_list $g_idx $g_idx]
}
puts "params: $params"
puts "greedy_list: $greedy_list"

set lm_result [list_mlac $params]
set start_time_list [lindex $lm_result 0]
set latency [lindex $lm_result 1]
foreach pair $start_time_list {
	set node_id [lindex $pair 0]
	set start_time [lindex $pair 1]
	#puts "Node: [get_attribute $node_id label] starts @ $start_time"
}
puts "FIRST RUN (WORST CASE LATENCY): $latency, AREA: $area"

set feasibility 1
set max_area 150
set index_greedy -1
set cycle 1


while { $cycle >= 0 } {
	set area 0
	set p_temp $params
	if {[llength $greedy_list] >  [expr {$index_greedy + 1}]} {
		incr index_greedy
	} else {
		break
	}
	set g_op [lindex [lindex $greedy_list $index_greedy] 3]
	set g_fu [lindex [lindex $greedy_list $index_greedy] 0]
	#find the index of the operation to replace
	set index_param [lsearch -index 2 $params $g_op]
	lset p_temp $index_param 0 $g_fu
	foreach fu $p_temp {
		set area [expr {$area + [get_attribute [lindex $fu 0] area]} ]
	}
	if {$area <= $max_area } {
		set params $p_temp
		#set params {{LO 1 MUL} {L1 1 ADD} {L2 1 SUB} {L2 1 LOD}}
puts "params: $params"
		set lm_result [list_mlac $params]
		set start_time_list [lindex $lm_result 0]
		set latency [lindex $lm_result 1]
		foreach pair $start_time_list {
			set node_id [lindex $pair 0]
			set start_time [lindex $pair 1]
			#puts "Node: [get_attribute $node_id label] starts @ $start_time"
		}
		puts "Latency: $latency, AREA: $area"
	}
	incr cycle
}

print_dfg $output_dot
print_scheduled_dfg $start_time_list $output_dot
