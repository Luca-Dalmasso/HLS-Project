proc brave_opt args {
  array set options {-total_area 0}
  if { [llength $args] != 2 } {
    return -code error "Use brave_opt with -total_area \$area_value\$"
  }
  foreach {opt val} $args {
    if {![info exist options($opt)]} {
      return -code error "unknown option \"$opt\""
    }
    set options($opt) $val
  }
  set total_area $options(-total_area)

  puts $total_area
  source contest2.tcl
  return [get_total_scheduling $total_area]
}
