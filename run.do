vlog sync_simple_dual_port_ram_tb.v
vsim tb
add wave -r sim:/tb/*
run -all
