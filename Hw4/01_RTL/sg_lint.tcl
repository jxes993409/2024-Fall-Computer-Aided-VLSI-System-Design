##Data Import Section

read_file -type verilog IOTDF.v
read_file -type verilog DES.v
read_file -type verilog S_BOX.v
read_file -type verilog MAXMIN.v
read_file -type verilog CRC.v

##Common Options Section
set_option top IOTDF
set_option enableV05 yes
set_option enableSV yes


current_goal Design_Read -top IOTDF
link_design -force

current_goal lint/lint_rtl -top IOTDF
run_goal

current_goal lint/lint_rtl_enhanced -top IOTDF
run_goal

capture ./spyglass-1/IOTDF/lint/lint_rtl/spyglass_reports/spyglass_lint_violations.rpt {write_report spyglass_violations}
file copy -force ./spyglass-1/IOTDF/lint/lint_rtl/spyglass_reports/spyglass_lint_violations.rpt ./spyglass_lint_violations.rpt

capture ./spyglass-1/IOTDF/lint/lint_rtl_enhanced/spyglass_reports/spyglass_lint_enhanced_violations.rpt {write_report spyglass_violations}
file copy -force ./spyglass-1/IOTDF/lint/lint_rtl_enhanced/spyglass_reports/spyglass_lint_enhanced_violations.rpt ./spyglass_lint_enhanced_violations.rpt

exit -force