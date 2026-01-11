transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vlog -vlog01compat -work work +incdir+. {t1c_riscv_cpu.vo}

vlog -vlog01compat -work work +incdir+C:/Users/Rakshit\ Joshi/Downloads/t1c_riscv_cpu/t1c_riscv_cpu/.test {C:/Users/Rakshit Joshi/Downloads/t1c_riscv_cpu/t1c_riscv_cpu/.test/tb.v}

vsim -t 1ps -L altera_ver -L cycloneive_ver -L gate_work -L work -voptargs="+acc"  tb

add wave *
view structure
view signals
run 2000 ns
