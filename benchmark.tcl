#!/usr/bin/tclsh

source ./tcl_scripts/setenv.tcl
source ./tcl_scripts/sanity_topological_sort.tcl


#testing for RTL library 2
read_library ./data/RTL_libraries/RTL_lib_2.txt
#sourcing MAIN script
source ./braveOpt.tcl

set path_list [list arf.dot collapse_pyr_dfg__113.dot ewf.dot feedback_points_dfg__7.dot fir.dot h2v2_smooth_downsample_dfg__6.dot horner_bezier_surf_dfg__12.dot idctcol_dfg__3.dot interpolate_aux_dfg__12.dot invert_matrix_general_dfg__3.dot jpeg_fdct_islow_dfg__6.dot jpeg_idct_ifast_dfg__6.dot matmul_dfg__3.dot motion_vectors_dfg__7.dot smooth_color_z_triangle_dfg__31.dot write_bmp_header_dfg__7.dot]

proc do_things {path} {
	puts "NEW DFG: $path\n\n"
	catch {remove_design}
	read_design $path
	set max_area 195
	set clk_start [clock clicks]
	set ret [brave_opt -total_area $max_area]
	puts "execution time: [expr [clock clicks] - $clk_start] us"
	puts "[lindex $ret 0]"
	foreach fu_line [lindex $ret 1] {
		set node_op [get_attribute [lindex $fu_line 0] operation]
		set fu_op [get_attribute [lindex $fu_line 1] operation]
		if {$node_op != $fu_op } {
			puts "*****************************************ERROR*************************************"
		}
	}

	#sanity checks
	set nodes_scheduled ""
	foreach item [lindex $ret 0] {
		lappend nodes_scheduled [lindex $item 0]
	}
	puts "[sanity $nodes_scheduled]"
	set levels [lindex [get_levels] 0]
	puts "[sanity $levels]\n\n"
}

foreach i $path_list {
	do_things "./data/DFGs/$i"
}
