#!/usr/bin/tclsh

variable distance 0
variable node_priority [list]
variable node_visited [list]


proc depth_visit node {
	set nodeINDEX [lsearch -index 0 $::node_visited $node]
	set ::node_visited [lreplace $::node_visited $nodeINDEX $nodeINDEX "$node 1"]
	foreach parent [get_attribute $node parents] {
		set has_visited [lindex [lindex $::node_visited [lsearch -index 0 $::node_visited $parent]] 1]
		if {$has_visited == 0} {
			
			set ::distance [expr {$::distance + 1}]
			depth_visit $parent
			set ::distance [expr {$::distance - 1}]
		}
	}
	if {$::distance > [lindex [lindex $::node_priority $nodeINDEX] 1]} {
		set ::node_priority [lreplace $::node_priority $nodeINDEX $nodeINDEX "$node $::distance"]
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
		#foreach node $::node_priority {
		#	puts "[get_attribute [lindex $node 0] label] level: [lindex $node 1]"
		#}		
	}
	set node_list [list]
	foreach node $::node_priority {
		lappend node_list [lindex $node 0]
	}
	return $node_list
}


proc get_levels {} {
	set top_order [get_sorted_nodes]
	set index 0
	foreach node $top_order {
		lappend ::node_priority "$node 0"
		lappend ::node_visited "$node 0"
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
