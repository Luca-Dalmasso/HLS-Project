#!/usr/bin/tclsh

source ./tcl_scripts/setenv.tcl
read_design ./data/DFGs/fir.dot
read_library ./data/RTL_libraries/RTL_lib_2.txt
set fus [list]
set real_fus [list]
set greedy_list [list]
set params [list]
source ./tcl_scripts/scheduling/list_mlac_contest.tcl

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
		lappend real_fus [lindex $fus $idx2 ]
	}
}

#puts "used fus (increasing area ordered): $real_fus"

#greedy list ordered by decreasing delay
#first list_scheduling iteration params set
foreach fu $real_fus {
	lappend greedy_list [list [lindex $fu 0 ] [lsort -integer -decreasing -index 2 [lindex $fu 1 ]]]
}

proc print_greedy {ordered_list} {
	foreach item $ordered_list {
		puts $item
	}
}

#different lists on different costs function
set greedy_delay list
set greedy_list_lod list
set greedy_list_add list


#manual tests for some cost functions

#1) cost function on DELAY
lset greedy_delay [lsort -integer -decreasing -index {1 0 1} $greedy_list]
puts "DELAY"
print_greedy $greedy_delay
#2) personalized order LOD
puts "LOD"
lset greedy_list_lod "{LOD {{L12 10 5} {L11 20 2} {L10 40 1}}} {MUL {{L6 40 10} {L5 70 5} {L4 100 2}}} {ADD {{L2 10 5} {L1 20 2} {L0 40 1}}} {STR {{L15 10 5} {L14 20 2} {L13 40 1}}}"
print_greedy $greedy_list_lod
#3) personalized order ADD
puts "ADD"
lset greedy_list_add "{ADD {{L2 10 5} {L1 20 2} {L0 40 1}}} {LOD {{L12 10 5} {L11 20 2} {L10 40 1}}} {MUL {{L6 40 10} {L5 70 5} {L4 100 2}}} {STR {{L15 10 5} {L14 20 2} {L13 40 1}}}"
print_greedy $greedy_list_add

set greedy_list $greedy_delay
puts "executing with"
print_greedy $greedy_list
set output_dot ./data/out/contest/testcontest.dot

#update params on new sorting

foreach fu $real_fus {
	lappend params [list [lindex [lindex [lindex $fu 1] 0] 0] 1 [lindex $fu 0]]
}


#puts "greedy list (decreasing delay ordered): $greedy_list"

set area 0
foreach fu $params {
	set area [expr {$area + [get_attribute [lindex $fu 0] area]} ]
}
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
set index_greedy 0
set index_fu 0
set cycle 1


while { $cycle >= 0 } {
	set area 0
	set p_temp $params
	if { [llength [ lindex [lindex $greedy_list $index_greedy] 1]] >  [expr {$index_fu + 1}] } {
		incr index_fu
	} else {
		set index_fu 1
		if {[llength $greedy_list] >  [expr {$index_greedy + 1}]} {
			incr index_greedy
		} else {
			break
		}
	}
	set index_param [lsearch -index 2 $params [lindex [lindex $greedy_list $index_greedy] 0] ]
	lset p_temp $index_param 0 [lindex [lindex [lindex [lindex $greedy_list $index_greedy] 1] $index_fu] 0]
	foreach fu $p_temp {
		set area [expr {$area + [get_attribute [lindex $fu 0] area]} ]
	}
	if {$area <= $max_area } {
		set params $p_temp
		#set params {{LO 1} {L1 1} {L2 1} {L2 1}}
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
