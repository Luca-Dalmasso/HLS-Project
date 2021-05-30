#!/usr/bin/tclsh

#given a list of nodes
#compute the percentage of each operation in the list
#usage example: list of nodes composing the critical path

proc get_percentage nodes {
	puts $nodes
	set op_type [list]
	foreach node $nodes {
		set operation [get_attribute $node operation]
	       	if {[lsearch -index 0 $op_type $operation ] == -1} {
			lappend op_type "$operation 1"
		} else {
			set index [lsearch -index 0 $op_type $operation]
			set current_count [lindex [lindex $op_type $index] 1] 
			incr current_count
			lset op_type $index 1 $current_count 
		}
	}
	
	set index 0
	set tot_nodes [llength $nodes]
	foreach item $op_type {
		set current_stat [format "%.2f" [expr {([lindex $item 1]*100.00)/$tot_nodes}]]
		lset op_type $index 1 $current_stat
		incr index
	}

	puts "$op_type"
	return [lsort -real -decreasing -index {1} $op_type]
}

