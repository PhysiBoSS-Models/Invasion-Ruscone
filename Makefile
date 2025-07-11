VERSION := $(shell grep . VERSION.txt | cut -f1 -d:)
PROGRAM_NAME := invasion_model

ifndef CC
	CC := gcc
endif
ifndef CXX
	CXX := g++
endif

# CXX := g++-mp-7 # typical macports compiler name
# CXX := g++-7 # typical homebrew compiler name 

# Check for environment definitions of compiler 
# e.g., on CXX = g++-7 on OSX
ifdef PHYSICELL_CPP 
	CXX := $(PHYSICELL_CPP)
endif

ifdef PHYSICELL_CC
	CC := $(PHYSICELL_CC)
endif

### MaBoSS configuration 
# MaBoSS max nodes
ifndef MABOSS_MAX_NODES
MABOSS_MAX_NODES = 64
endif

# MaBoSS directory
MABOSS_DIR = addons/PhysiBoSS/MaBoSS/engine
CUR_DIR = $(shell pwd)
CUSTOM_DIR = sample_projects/Arnau_model/custom_modules

ifneq ($(OS), Windows_NT)
	LDL_FLAG = -ldl
endif

LIB := -L$(CUR_DIR)/$(MABOSS_DIR)/lib -lMaBoSS-static $(LDL_FLAG)
INC := -DADDON_PHYSIBOSS -I$(CUR_DIR)/$(MABOSS_DIR)/include -DMAXNODES=$(MABOSS_MAX_NODES)


# If max nodes > 64, change lib path 
ifeq ($(shell expr $(MABOSS_MAX_NODES) '>' 64), 1)
LIB := -L$(CUR_DIR)/$(MABOSS_DIR)/lib -lMaBoSS_$(MABOSS_MAX_NODES)n-static $(LDL_FLAG)
endif

ifndef STATIC_OPENMP
	STATIC_OPENMP = -fopenmp
endif

ARCH := native # best auto-tuning
# ARCH := core2 # a reasonably safe default for most CPUs since 2007
# ARCH := corei7
# ARCH := corei7-avx # earlier i7 
# ARCH := core-avx-i # i7 ivy bridge or newer 
# ARCH := core-avx2 # i7 with Haswell or newer
# ARCH := nehalem
# ARCH := westmere
# ARCH := sandybridge # circa 2011
# ARCH := ivybridge   # circa 2012
# ARCH := haswell     # circa 2013
# ARCH := broadwell   # circa 2014
# ARCH := skylake     # circa 2015
# ARCH := bonnell
# ARCH := silvermont
# ARCH := skylake-avx512
# ARCH := nocona #64-bit pentium 4 or later 

# CFLAGS := -march=$(ARCH) -Ofast -s -fomit-frame-pointer -mfpmath=both -fopenmp -m64 -std=c++11
CFLAGS := -g -march=$(ARCH) -O3 -fomit-frame-pointer -mfpmath=both -fopenmp -m64 -std=c++11
# debug:
# CFLAGS := -march=$(ARCH) -O0 -ggdb -fomit-frame-pointer -mfpmath=both -fopenmp -m64 -std=c++11

ifeq ($(OS),Windows_NT)
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Darwin)
		UNAME_P := $(shell uname -p)
		var := $(shell which $(CXX) | xargs file)
		ifeq ($(lastword $(var)),arm64)
		  CFLAGS := -march=$(ARCH) -O3 -fomit-frame-pointer -fopenmp -m64 -std=c++11
		endif
	endif
endif

CFLAGS_LINK := $(shell echo $(CFLAGS) | sed -e "s/-fopenmp//g")
COMPILE_COMMAND := $(CXX) $(CFLAGS)  $(EXTRA_FLAGS)
LINK_COMMAND := $(CXX) $(CFLAGS_LINK) $(EXTRA_FLAGS)

BioFVM_OBJECTS := BioFVM_vector.o BioFVM_mesh.o BioFVM_microenvironment.o BioFVM_solvers.o BioFVM_matlab.o \
BioFVM_utilities.o BioFVM_basic_agent.o BioFVM_MultiCellDS.o BioFVM_agent_container.o 

PhysiCell_core_OBJECTS := PhysiCell_phenotype.o PhysiCell_cell_container.o PhysiCell_standard_models.o \
PhysiCell_cell.o PhysiCell_custom.o PhysiCell_utilities.o PhysiCell_constants.o PhysiCell_basic_signaling.o \
PhysiCell_signal_behavior.o PhysiCell_rules.o


PhysiCell_module_OBJECTS := PhysiCell_SVG.o PhysiCell_pathology.o PhysiCell_MultiCellDS.o PhysiCell_various_outputs.o \
PhysiCell_pugixml.o PhysiCell_settings.o PhysiCell_geometry.o

# put your custom objects here (they should be in the custom_modules directory)

MaBoSS := ./addons/PhysiBoSS/MaBoSS/engine/src/BooleanNetwork.h

PhysiBoSS_OBJECTS := maboss_network.o maboss_intracellular.o

PhysiCell_custom_module_OBJECTS := custom.o

pugixml_OBJECTS := pugixml.o

PhysiCell_OBJECTS := $(BioFVM_OBJECTS)  $(pugixml_OBJECTS) $(PhysiCell_core_OBJECTS) $(PhysiCell_module_OBJECTS)
ALL_OBJECTS := $(PhysiCell_OBJECTS) $(PhysiCell_custom_module_OBJECTS) $(PhysiBoSS_OBJECTS)

# compile the project 

all: main.cpp $(ALL_OBJECTS) $(MaBoSS)
	$(COMPILE_COMMAND) $(INC) -o $(PROGRAM_NAME) $(ALL_OBJECTS) main.cpp $(LIB)
	make name

static: main.cpp $(ALL_OBJECTS) $(MaBoSS)
	$(LINK_COMMAND) $(INC) -o $(PROGRAM_NAME) $(ALL_OBJECTS) main.cpp $(LIB) -static-libgcc -static-libstdc++ $(STATIC_OPENMP)

name:
	@echo ""
	@echo "Executable name is" $(PROGRAM_NAME)
	@echo ""

# PhysiCell core components	

PhysiCell_phenotype.o: ./core/PhysiCell_phenotype.cpp
	$(COMPILE_COMMAND) -c ./core/PhysiCell_phenotype.cpp
	
PhysiCell_digital_cell_line.o: ./core/PhysiCell_digital_cell_line.cpp
	$(COMPILE_COMMAND) -c ./core/PhysiCell_digital_cell_line.cpp

PhysiCell_cell.o: ./core/PhysiCell_cell.cpp $(MaBoSS)
	$(COMPILE_COMMAND) $(INC) -c ./core/PhysiCell_cell.cpp 

PhysiCell_cell_container.o: ./core/PhysiCell_cell_container.cpp
	$(COMPILE_COMMAND) -c ./core/PhysiCell_cell_container.cpp 
	
PhysiCell_standard_models.o: ./core/PhysiCell_standard_models.cpp
	$(COMPILE_COMMAND) -c ./core/PhysiCell_standard_models.cpp 
	
PhysiCell_utilities.o: ./core/PhysiCell_utilities.cpp
	$(COMPILE_COMMAND) -c ./core/PhysiCell_utilities.cpp 
	
PhysiCell_custom.o: ./core/PhysiCell_custom.cpp
	$(COMPILE_COMMAND) -c ./core/PhysiCell_custom.cpp 

PhysiCell_constants.o: ./core/PhysiCell_constants.cpp
	$(COMPILE_COMMAND) -c ./core/PhysiCell_constants.cpp
	
PhysiCell_signal_behavior.o: ./core/PhysiCell_signal_behavior.cpp
	$(COMPILE_COMMAND) -c ./core/PhysiCell_signal_behavior.cpp 

PhysiCell_rules.o: ./core/PhysiCell_rules.cpp
	$(COMPILE_COMMAND) -c ./core/PhysiCell_rules.cpp 
	
# BioFVM core components (needed by PhysiCell)
	
BioFVM_vector.o: ./BioFVM/BioFVM_vector.cpp
	$(COMPILE_COMMAND) -c ./BioFVM/BioFVM_vector.cpp 

BioFVM_agent_container.o: ./BioFVM/BioFVM_agent_container.cpp
	$(COMPILE_COMMAND) -c ./BioFVM/BioFVM_agent_container.cpp 
	
BioFVM_mesh.o: ./BioFVM/BioFVM_mesh.cpp
	$(COMPILE_COMMAND) -c ./BioFVM/BioFVM_mesh.cpp 

BioFVM_microenvironment.o: ./BioFVM/BioFVM_microenvironment.cpp
	$(COMPILE_COMMAND) -c ./BioFVM/BioFVM_microenvironment.cpp 

BioFVM_solvers.o: ./BioFVM/BioFVM_solvers.cpp
	$(COMPILE_COMMAND) -c ./BioFVM/BioFVM_solvers.cpp 

BioFVM_utilities.o: ./BioFVM/BioFVM_utilities.cpp
	$(COMPILE_COMMAND) -c ./BioFVM/BioFVM_utilities.cpp 
	
BioFVM_basic_agent.o: ./BioFVM/BioFVM_basic_agent.cpp
	$(COMPILE_COMMAND) -c ./BioFVM/BioFVM_basic_agent.cpp 
	
BioFVM_matlab.o: ./BioFVM/BioFVM_matlab.cpp
	$(COMPILE_COMMAND) -c ./BioFVM/BioFVM_matlab.cpp

BioFVM_MultiCellDS.o: ./BioFVM/BioFVM_MultiCellDS.cpp
	$(COMPILE_COMMAND) -c ./BioFVM/BioFVM_MultiCellDS.cpp
	
pugixml.o: ./BioFVM/pugixml.cpp
	$(COMPILE_COMMAND) -c ./BioFVM/pugixml.cpp
	
# standard PhysiCell modules

PhysiCell_SVG.o: ./modules/PhysiCell_SVG.cpp
	$(COMPILE_COMMAND) -c ./modules/PhysiCell_SVG.cpp

PhysiCell_pathology.o: ./modules/PhysiCell_pathology.cpp
	$(COMPILE_COMMAND) -c ./modules/PhysiCell_pathology.cpp

PhysiCell_MultiCellDS.o: ./modules/PhysiCell_MultiCellDS.cpp $(MaBoSS)
	$(COMPILE_COMMAND) $(INC) -c ./modules/PhysiCell_MultiCellDS.cpp

PhysiCell_various_outputs.o: ./modules/PhysiCell_various_outputs.cpp
	$(COMPILE_COMMAND) -c ./modules/PhysiCell_various_outputs.cpp
	
PhysiCell_pugixml.o: ./modules/PhysiCell_pugixml.cpp
	$(COMPILE_COMMAND) -c ./modules/PhysiCell_pugixml.cpp
	
PhysiCell_settings.o: ./modules/PhysiCell_settings.cpp
	$(COMPILE_COMMAND) -c ./modules/PhysiCell_settings.cpp	
	
PhysiCell_basic_signaling.o: ./core/PhysiCell_basic_signaling.cpp
	$(COMPILE_COMMAND) -c ./core/PhysiCell_basic_signaling.cpp 	
	
PhysiCell_geometry.o: ./modules/PhysiCell_geometry.cpp
	$(COMPILE_COMMAND) -c ./modules/PhysiCell_geometry.cpp 	

# user-defined PhysiCell modules
Compile_MaBoSS: ./addons/PhysiBoSS/MaBoSS/engine/src/BooleanNetwork.h
	cd ./addons/PhysiBoSS/MaBoSS/engine/src;make CXX=$(CXX) CC=$(CC) MAXNODES=$(MABOSS_MAX_NODES) install_alib;make clean; cd ../../../../..

$(MaBoSS): 
ifeq ($(OS), Windows_NT)
	python addons/PhysiBoSS/setup_libmaboss.py
else
	python3 addons/PhysiBoSS/setup_libmaboss.py
endif

maboss_network.o: ./addons/PhysiBoSS/src/maboss_network.cpp $(MaBoSS)
	$(COMPILE_COMMAND) $(INC) -c ./addons/PhysiBoSS/src/maboss_network.cpp

maboss_intracellular.o: ./addons/PhysiBoSS/src/maboss_intracellular.cpp $(MaBoSS)
	$(COMPILE_COMMAND) $(INC) -c ./addons/PhysiBoSS/src/maboss_intracellular.cpp

custom.o: ./custom_modules/custom.cpp $(MaBoSS)
	$(COMPILE_COMMAND) $(INC) -c ./custom_modules/custom.cpp

# cleanup

reset:
	rm -f *.cpp 
	cp ./sample_projects/Makefile-default Makefile 
	rm -f ./custom_modules/*
	touch ./custom_modules/empty.txt 
	touch ALL_CITATIONS.txt 
	rm ALL_CITATIONS.txt 
	rm ./config/PhysiCell_settings_*.xml
	cp ./config/PhysiCell_settings-backup.xml ./config/PhysiCell_settings.xml 
	rm -rf ./config/boolean_network/ ./config/cells.csv ./config/rules.csv ./config/init.tsv
	rm -rf ./scripts

MaBoSS-clean:
	rm -fr addons/PhysiBoSS/MaBoSS
	
clean:
	rm -f *.o
	rm -f $(PROGRAM_NAME)*
	
data-cleanup:
	rm -f *.mat
	rm -f *.xml
	rm -f *.svg
	rm -rf ./output
	mkdir ./output
	touch ./output/empty.txt
	
# archival 

checkpoint: 
	zip -r $$(date +%b_%d_%Y_%H%M).zip Makefile *.cpp *.h config/*.xml custom_modules/* 

zip:
	zip -r latest.zip Makefile* *.cpp *.h BioFVM/* config/* core/* custom_modules/* matlab/* modules/* sample_projects/* 
	cp latest.zip $$(date +%b_%d_%Y_%H%M).zip
	cp latest.zip VERSION_$(VERSION).zip 
	mv *.zip archives/
	
tar:
	tar --ignore-failed-read -czf latest.tar Makefile* *.cpp *.h BioFVM/* config/* core/* custom_modules/* matlab/* modules/* sample_projects/* 
	cp latest.tar $$(date +%b_%d_%Y_%H%M).tar
	cp latest.tar VERSION_$(VERSION).tar
	mv *.tar archives/

unzip: 
	cp ./archives/latest.zip . 
	unzip latest.zip 
	
untar: 
	cp ./archives/latest.tar .
	tar -xzf latest.tar

movie:
	ffmpeg -r 25 -i output/snapshot%08d.svg -pix_fmt yuv420p output.mp4
	vlc output.mp4
	
# upgrade rules 

SOURCE := PhysiCell_upgrade.zip 
get-upgrade: 
	@echo $$(curl https://raw.githubusercontent.com/MathCancer/PhysiCell/master/VERSION.txt) > VER.txt 
	@echo https://github.com/MathCancer/PhysiCell/releases/download/$$(grep . VER.txt)/PhysiCell_V.$$(grep . VER.txt).zip > DL_FILE.txt 
	rm -f VER.txt
	$$(curl -L $$(grep . DL_FILE.txt) --output PhysiCell_upgrade.zip)
	rm -f DL_FILE.txt 

PhysiCell_upgrade.zip: 
	make get-upgrade 

upgrade: $(SOURCE)
	unzip $(SOURCE) PhysiCell/VERSION.txt
	mv -f PhysiCell/VERSION.txt . 
	unzip $(SOURCE) PhysiCell/core/* 
	cp -r PhysiCell/core/* core 
	unzip $(SOURCE) PhysiCell/modules/* 
	cp -r PhysiCell/modules/* modules 
	unzip $(SOURCE) PhysiCell/sample_projects/* 
	cp -r PhysiCell/sample_projects/* sample_projects 
	unzip $(SOURCE) PhysiCell/BioFVM/* 
	cp -r PhysiCell/BioFVM/* BioFVM
	unzip $(SOURCE) PhysiCell/documentation/User_Guide.pdf
	mv -f PhysiCell/documentation/User_Guide.pdf documentation
	rm -f -r PhysiCell
	rm -f $(SOURCE) 
	
# use: make save PROJ=your_project_name
PROJ := my_project

save: 
	echo "Saving project as $(PROJ) ... "
	mkdir -p ./user_projects
	mkdir -p ./user_projects/$(PROJ)
	mkdir -p ./user_projects/$(PROJ)/custom_modules
	mkdir -p ./user_projects/$(PROJ)/config 
	cp main.cpp ./user_projects/$(PROJ)
	cp Makefile ./user_projects/$(PROJ)
	cp VERSION.txt ./user_projects/$(PROJ)
	cp -r ./config/* ./user_projects/$(PROJ)/config
	cp -r ./custom_modules/* ./user_projects/$(PROJ)/custom_modules

load: 
	echo "Loading project from $(PROJ) ... "
	cp ./user_projects/$(PROJ)/main.cpp .
	cp ./user_projects/$(PROJ)/Makefile .
	cp -r ./user_projects/$(PROJ)/config/* ./config/ 
	cp -r ./user_projects/$(PROJ)/custom_modules/* ./custom_modules/ 

pack:
	@echo " "
	@echo "Preparing project $(PROJ) for sharing ... "
	@echo " " 
	cd ./user_projects && zip -r $(PROJ).zip $(PROJ)
	@echo " "
	@echo "Share ./user_projects/$(PROJ).zip ... "
	@echo "Other users can unzip $(PROJ).zip in their ./user_projects, compile, and run."
	@echo " " 

unpack:
	@echo " "
	@echo "Preparing shared project $(PROJ).zip for use ... "
	@echo " " 
	cd ./user_projects && unzip $(PROJ).zip 
	@echo " "
	@echo "Load this project via make load PROJ=$(PROJ) ... "
	@echo " " 	

list-user-projects:
	@echo "user projects::"
	@cd ./user_projects && ls -dt1 * | grep . | sed 's!empty.txt!!'
