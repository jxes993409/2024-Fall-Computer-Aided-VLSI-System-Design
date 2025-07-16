##Data Import Section

read_file -type verilog core.v
read_file -type gateslib ../sram_512x8/sram_512x8_slow_syn.lib
read_file -type verilog odd_even_sort.v
read_file -type verilog divider.v

##Common Options Section
set_option top core
set_option enableV05 yes
set_option enableSV yes


current_goal Design_Read -top core
link_design -force

current_goal lint/lint_rtl -top core
run_goal

current_goal lint/lint_rtl_enhanced -top core
run_goal

capture ./spyglass-1/core/lint/lint_rtl/spyglass_reports/spyglass_lint_violations.rpt {write_report spyglass_violations}
file copy -force ./spyglass-1/core/lint/lint_rtl/spyglass_reports/spyglass_lint_violations.rpt ./spyglass_lint_violations.rpt

capture ./spyglass-1/core/lint/lint_rtl_enhanced/spyglass_reports/spyglass_lint_enhanced_violations.rpt {write_report spyglass_violations}
file copy -force ./spyglass-1/core/lint/lint_rtl_enhanced/spyglass_reports/spyglass_lint_enhanced_violations.rpt ./spyglass_lint_enhanced_violations.rpt

exit -force