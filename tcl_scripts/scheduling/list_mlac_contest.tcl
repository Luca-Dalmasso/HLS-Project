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
puts "Time $start_time, scheduled $node, label: $lbl, op: $op, resource usage: $fu_res_used"
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
puts "already scheduled node $node, ts: $ts, end: [expr $ts + $duration]"
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
