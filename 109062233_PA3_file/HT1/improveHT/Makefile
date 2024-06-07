# set VENDOR_HOME = /usr/cad/synopsys/verdi/cur

.PHONY:all com sim cov clean test_verdi urg filelist

dll_path = /home/tools/verdi/2020.03/share/PLI/VCS/linux64/novas.tab
la_path = /home/tools/verdi/2020.03/share/PLI/VCS/linux64/pli.a

# Define additional library paths
LIB_PATHS = /home/tools/verdi/2020.03/share/PLI/VCS/linux64

OUTPUT = aes128
FSDB_FILENAME = ${OUTPUT}.fsdb
# name for the output 
VPD_NAME = +vpdfile+${OUTPUT}.vpd

# code coverage for verdi 
# Code coverage command
# we wan to converage the line, condition, fsm , branch and the toggle 
CM = -cm line+cond+fsm+branch+tgl
CM_NAME = -cm_name $(OUTPUT)
CN_DIR = -cm_dir ./$(OUTPUT).vdb

# Seed for the random number generator
SEED = 12345  # Change this value to set a different seed

# full64 以64bit模式编译，输出文件是64bit
# sverilog support system verilog
# v2k support verilog 2001
# ldclass support the library (传递参数给VCS的linker)
# -l log 
# -o object name 
# debug_acc+all enable the debug access
VCS = vcs -sverilog +v2k -timescale=1ns/1ns  \
	-full64 \
	-debug_acc+all \
	-o ${OUTPUT}	\
	-l compile.log \
	-LDCLASS \
	-P ${dll_path} ${la_path} \
	${CM} ${CM_NAME} ${CN_DIR}

# filelist will place all the .v file into the filelist.f
filelist:
	find . -name "*.v" > verilog_file.f

SIM = ./${OUTPUT} ${VPD_NAME} -l ${OUTPUT}.log ${CM} ${CM_NAME} ${CN_DIR} +ntb_random_seed=${SEED} #+fsdbfile+$(FSDB_FILENAME)

# this is to make the file compiled 
com:
	${VCS} -f verilog_file.f -P ${dll_path}

# two things 1. add the library path 2. run the simulation
sim:
	export LD_LIBRARY_PATH=${LIB_PATHS}:$$LD_LIBRARY_PATH && ${SIM} 

# formally the we should use the fsdb file to generate the coverage report
verdi:
	verdi -f verilog_file.f -ssf aes.fsdb  & 

# this is the unformal way to generate the coverage report
# the reference for the csdn is wrong, it should be -covdir instead of -cov_dir
cov:
	verdi -cov -covdir ./${OUTPUT}.vdb 

all: filelist com sim cov

# this will generate the html report and the text report 
urg:
	urg -dir ${OUTPUT}.vdb -report both

clean:
	rm -rf ./csrc *.daidir *.log *.simv *.conf *.key *.vpd ./DVEfiles ./verdiLog *.rc ./vdCovLog ./aes128.vdb *.fsdb ./both aes128 verilog_file.f