variable distance 0
variable node_visited [list]

proc prepare_fu_list {} {
	set fus [list]
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

	set real_fus [list]
	#used fus grouped by type of op (internally ordered as before)
	foreach node [get_nodes] {
		set op [get_attribute $node operation]
		set idx [lsearch $real_fus [list $op *]]
		if {$idx<0} {
			set idx2 [lsearch $fus [list $op *]]
			if {$idx2<0} {
				puts "error, no fu found to execute $op"
				exit 2
			}
			lappend real_fus [lindex $fus $idx2]
			foreach fu [lindex [lindex $fus $idx2] 1] {
				lappend greedy_list_decreasing_delay [lappend fu $op]
			}
		}
	}
	#puts "used fus (increasing area ordered): $real_fus"

	#our cost function
	set greedy_list_decreasing_delay [lsort -integer -decreasing -index 2 $greedy_list_decreasing_delay]
	return [list $real_fus $greedy_list_decreasing_delay]
}

proc get_total_scheduling {max_area} {

	set clk_start [clock clicks]

	set levels_result [get_levels]
	set level_node_list [lindex $levels_result 0]
	set max_number_units [lindex $levels_result 1]

	set p_result [prepare_fu_list]
	set real_fus [lindex $p_result 0]
	set greedy_list [lindex $p_result 1]
	set params [list]
	set area 0
	#puts "get_total_scheduling: $max_area"
	#prepare params for the first run
	foreach fu $real_fus {
		set op [lindex $fu 0]
		set smallest_fu [lindex [lindex [lindex $fu 1] 0] 0]
		lappend params [list $smallest_fu 1 $op]
		set area [expr {$area + [get_attribute $smallest_fu area]} ]
	}
	#puts "executing with $greedy_list\n"
	#puts "params: $params\n"
	set lm_result [list_mlac $params $level_node_list]
	set start_time_list [lindex $lm_result 0]
	set latency [lindex $lm_result 1]
	set feasibility 1
	set index_greedy -1
	set cycle 1

	while { $cycle >= 0 } {
		if {[llength $greedy_list] >  [expr {$index_greedy + 1}]} {
			incr index_greedy
		} else {
			break
		}
		set g_op [lindex [lindex $greedy_list $index_greedy] 3]
		set g_fu [lindex [lindex $greedy_list $index_greedy] 0]
		set index_param [lsearch -index 2 $params $g_op]
		set p_temp $params
		lset p_temp $index_param 0 $g_fu
		set max_idx [lsearch -index 0 $max_number_units $g_op]

		for {set i 1} {$i <= [lindex [lindex $max_number_units $max_idx] 1]} {incr i} {
			set area 0
			#replace the old fu with the new one (or with the same but with an increased # of resources)
			lset p_temp $index_param 1 $i
			foreach fu $p_temp {
				set area [expr {$area + [expr [lindex $fu 1]*[get_attribute [lindex $fu 0] area]]} ]
			}
			if {$area <= $max_area } {
				set params $p_temp
				#puts "\nparams: $params"
				set lm_result [list_mlac $params $level_node_list]
				set latency [lindex $lm_result 1]
				#puts "\nLatency: $latency, AREA: $area"
			}
			incr cycle
		}
	}
	set node_fu_list [list]
	foreach node [get_nodes] {
		set index_param [lsearch -index 2 $params [get_attribute $node operation]]
		lappend node_fu_list [list $node [lindex [lindex $params $index_param] 0]]
	}
	set fu_res_list [list]
	foreach p $params {
		lappend fu_res_list [list [lindex $p 0] [lindex $p 1]]
	}
	#last list_scheduling result
	set start_time_list [lindex $lm_result 0]

	puts "execution time: [expr [clock clicks] - $clk_start] us"

	return [list $start_time_list $node_fu_list $fu_res_list]
}

proc depth_visit node {
	set nodeINDEX [lsearch -index 0 $::node_priority $node]
	foreach parent [get_attribute $node parents] {
		set ::distance [expr {$::distance + 1}]
		depth_visit $parent
		set ::distance [expr {$::distance - 1}]
	}
	if {$nodeINDEX == -1} {
		lappend ::node_priority "$node $::distance"
	} else {
		if {$::distance > [lindex [lindex $::node_priority $nodeINDEX] 1]} {
			set ::node_priority [lreplace $::node_priority $nodeINDEX $nodeINDEX "$node $::distance"]
		}
	}
}

proc get_sinks nodes {
	set sinks [list]
	foreach node $nodes {
		if {[llength [get_attribute $node children]] == 0} {
			lappend sinks $node
		}
	}
	return $sinks
}

proc priority_wrapper {nodes} {
	set sinks [get_sinks $nodes]
	foreach sink $sinks {
		set ::distance 0
		depth_visit $sink
		set ::node_priority [lsort -index 1 -integer -decreasing $::node_priority]
	}
	set node_list [list]
	foreach node $::node_priority {
		lappend node_list [lindex $node 0]
	}
	return $node_list
}

proc reset {} {
	set ::distance 0
	set ::node_priority ""
}

proc get_levels {} {
	reset
	set top_order [get_sorted_nodes]
	set index 0
	foreach node $top_order {
		lappend ::node_priority "$node 0"
		incr index
	}
	set l_nodes [priority_wrapper $top_order]
	return [list $l_nodes [get_max_levels]]
}

proc get_max_levels {} {
	set nodes $::node_priority
	set current_level [lindex [lindex $nodes 0] 1]
	set max_list [list]
	set level_list [list]
	foreach node $nodes {
		#{{node priority}}
		set op [get_attribute [lindex $node 0] operation]
		set level [lindex $node 1]

		if { $current_level != $level } {
			set current_level $level
			foreach lvl $level_list {
				set lvl_op [lindex $lvl 0]
				set lvl_max [lindex $lvl 1]

				set max_idx [lsearch -index 0 $max_list $lvl_op]
				if {$max_idx == -1} {
					lappend max_list "$lvl_op $lvl_max"
				} else {
					set current_max [lindex [lindex $max_list $max_idx] 1]
					if {$lvl_max > $current_max } {
						lset max_list $max_idx 1 $lvl_max
					}
				}
			}
			set level_list [list]
		}

			set op_idx [lsearch -index 0 $level_list $op]
			if {$op_idx == -1} {
				lappend level_list "$op 1"
			} else {
				set current_count [lindex [lindex $level_list $op_idx] 1]
				incr current_count
				lset level_list $op_idx 1 $current_count
			}
	}
			set current_level $level
			foreach lvl $level_list {
				set lvl_op [lindex $lvl 0]
				set lvl_max [lindex $lvl 1]

				set max_idx [lsearch -index 0 $max_list $lvl_op]
				if {$max_idx == -1} {
					lappend max_list "$lvl_op $lvl_max"
				} else {
					set current_max [lindex [lindex $max_list $max_idx] 1]
					if {$lvl_max > $current_max } {
						lset max_list $max_idx 1 $lvl_max
					}
				}
			}
			set level_list [list]

	return $max_list
}

proc list_mlac {fu_res nodes} {

  set node_start_time [list]
  set fu_res_used [list]
  set abs_start_time 1
  set start_time 1
  set n [llength $nodes]
  set sched_nodes [list]
  set i 0
  set end_time 0

  foreach fu $fu_res {
	lappend fu_res_used [list [lindex $fu 0] 0]
  }

  while { $i<$n } {
	set fuIdx 0
	foreach fu_row $fu_res {
		set fu [lindex $fu_row 0]
		set op [get_attribute $fu operation]
#puts "op: $op"
		set duration [get_attribute $fu delay]
		set res [lindex $fu_row 1]
		foreach node $nodes {
			set nodeOp [get_attribute $node operation]
			set lbl [get_attribute $node label]
			set resUsed [lindex [lindex $fu_res_used $fuIdx] 1]
#puts "NODE: $node, nodeOp: $nodeOp, op: $op, res: $res, resUsed: $resUsed"

			set sched 1
			foreach par [get_attribute $node parents] {
				if {[lsearch $nodes $par]>=0 || [lsearch $sched_nodes $par]>=0 } {
					set sched 0
				}
			}

			if {[string equal $nodeOp $op] && $sched==1 && $res>$resUsed } {
				set fu_res_used [lreplace $fu_res_used $fuIdx $fuIdx [list $fu [expr $resUsed + 1]]]
				lappend node_start_time [list $node $start_time]
				set nodeIdx [lsearch $nodes $node]
				set nodes [lreplace $nodes $nodeIdx $nodeIdx]
				incr i
#puts "Time $start_time, scheduled $node, label: $lbl, op: $op, resource usage: $fu_res_used"
				lappend sched_nodes $node
				set endTimeTmp [expr $start_time + $duration ]
				if {$endTimeTmp > $end_time } {
					set end_time $endTimeTmp
				}
			}
		}
		incr fuIdx
	}
	incr start_time
#puts "st increment $start_time"
#puts "scheduled nodes:"
	foreach node $sched_nodes {
		set nodeOp [get_attribute $node operation]
#puts "$node ($nodeOp)"
		set idxx 0
		foreach fu_row $fu_res {
			set fu [lindex $fu_row 0]
			set fu_op [get_attribute $fu operation]
			if {$fu_op eq $nodeOp } {
				set duration [get_attribute $fu delay]
				set fuIdx $idxx
				break
			}
			incr idxx
		}
  		set ts [lsearch $node_start_time [list $node *]]
  		if {$ts>=0} {
			set ts [lindex [lindex $node_start_time $ts] 1]
#puts "already scheduled node $node, ts: $ts, end: [expr $ts + $duration]"
			if {$start_time == [expr $ts + $duration]} {
				set tmpRes [lindex [lindex $fu_res_used $fuIdx] 1]
#puts "fuIdx: $fuIdx, tmpRes: $tmpRes"
				set fu_res_used [lreplace $fu_res_used $fuIdx $fuIdx [list $fu [expr $tmpRes - 1]]]
				set nodeIdx [lsearch $sched_nodes $node]
				set sched_nodes [lreplace $sched_nodes $nodeIdx $nodeIdx]
			}
		}

	}

  }

  return [list $node_start_time [expr $end_time - $abs_start_time]]

}
