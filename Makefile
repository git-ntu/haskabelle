#############
# variables #
#############

# the haskell compiler to use
HC      = ghc
# the options for the haskell compiler
HC_OPTS = -fglasgow-exts
# the directory to put the object files to
OUT_DIR = out
# the directory to put the optimised object files to
OOUT_DIR = oout
# the directory to put the interface files to
HI_DIR = hi
# the directory to put the interface files for optimised compiling to
OHI_DIR = ohi
# the directory to put the interface documentation to
HADDOCK_DIR = doc/interface
# the directory to put the implementation documentation to
HADDOCK_IMPL_DIR = doc/impl
# the directory to put the built binaries to
BUILD_DIR = build
# the filename for the default binary
BIN_NAME = importer
# the filename for the optimised binary
OBIN_NAME = imp
# optimisation flags (only used for the "optimised" target)
OFLAGS = -O2

################################
# derived variable / functions #
################################

# function that takes one argument that is supposed to be a file path
# and returns recursively all .hs and .lhs files contained below this
# path.
search_srcs = \
	$(foreach file, \
		$(wildcard $(1)/*), \
		$(filter %.hs %lhs,$(file)) $(call search_srcs,$(file)) \
	) 
# all source files
SRCS = $(wildcard  *.hs) $(call search_srcs,Importer)
# the corresponding object files
OBJS = $(SRCS:%.hs=$(OUT_DIR)/%.o)
# the corresponding optimisedd object files
OOBJS = $(SRCS:%.hs=$(OOUT_DIR)/%.o)
# the corresponding interface files
HIS = $(SRCS:%.hs=$(HI_DIR)/%.hi)

# a list of all directories that might need to be created
ALL_DIRS = $(HADDOCK_DIR) $(HADDOCK_IMPL_DIR) $(BUILD_DIR) $(HI_DIR) $(OHI_DIR) $(OUT_DIR) $(OOUT_DIR)
# list of the packages needed
PACKAGES = uniplate base haskell-src-exts
# this is used as a command line argument for ghc to include the 
# packages as stated in the variable PACKAGES
PKGS = $(foreach pkg,$(PACKAGES),-package $(pkg))
USE_PKGS = $(foreach pkg,$(PACKAGES),--use-package=$(pkg))

################
# declarations #
################

.PHONY : clean clean-optimised depend build rebuild rebuild-optimised haddock haddock-impl
.SUFFIXES : .o .hs .hi .lhs .hc .s

#######################
# compilation targets #
#######################

# builds the default binary
default : $(BUILD_DIR)/$(BIN_NAME)
	@:
# builds the optimised binary
optimised : $(BUILD_DIR)/$(OBIN_NAME)
	@:

# builds the optimised binary
$(BUILD_DIR)/$(OBIN_NAME) : $(OOBJS) $(BUILD_DIR)
	@rm -f $@
	@echo linking optimised binary ...
	@$(HC) -o $@ $(HC_OPTS) -hidir $(OHI_DIR) -odir $(OOUT_DIR) $(PKGS) $(OOBJS) $(OFLAGS)

# builds the default binary
$(BUILD_DIR)/$(BIN_NAME) : $(OBJS) $(BUILD_DIR)
	@rm -f $@
	@echo linking default binary ...
	@$(HC) -o $@ $(HC_OPTS) -hidir $(HI_DIR) -odir $(OUT_DIR) $(PKGS) $(OBJS)


# cleans the optimised compilation
clean-optimised:
	@echo cleaning optimised build ...
	@rm -f  $(BUILD_DIR)/$(OBIN_NAME)
	@rm -fr $(OOUT_DIR)/*
	@rm -fr $(OHI_DIR)/*

# cleans the default compilaton
clean : 
	@echo cleaning default build ...
	@rm -f  $(BUILD_DIR)/$(BIN_NAME)
	@rm -fr $(OUT_DIR)/*
	@rm -fr $(HI_DIR)/*

# rebuilds the optimised binary
rebuild-optimised : clean-optimised optimised
	@:

# rebuilds the default binary
rebuild : clean default
	@:
#########################
# Standard suffix rules #
#########################


$(HI_DIR)/%.hi : $(OUT_DIR)/%.o $(HI_DIR)
	@:

$(OHI_DIR)/%.hi : $(OOUT_DIR)/%.o $(OHI_DIR)
	@:

$(OUT_DIR)/%.o: %.lhs $(OUT_DIR)
	@echo compiling $< ...
	@$(HC) -c $< -i$(HI_DIR) -odir $(OUT_DIR) -hidir $(HI_DIR) $(HC_OPTS)

$(OUT_DIR)/%.o: %.hs  $(OUT_DIR)
	@echo compiling $< ...
	@$(HC) -c $< -i$(HI_DIR) -odir $(OUT_DIR) -hidir $(HI_DIR) $(HC_OPTS)

$(OOUT_DIR)/%.o: %.lhs $(OOUT_DIR)
	@echo optimised compiling $< ...
	@$(HC) -c $< -i$(OHI_DIR) -odir $(OOUT_DIR) -hidir $(OHI_DIR) $(HC_OPTS) $(OFLAGS)

$(OOUT_DIR)/%.o: %.hs $(OOUT_DIR)
	@echo optimised compiling $< ...
	@$(HC) -c $< -i$(OHI_DIR) -odir $(OOUT_DIR) -hidir $(OHI_DIR) $(HC_OPTS) $(OFLAGS)

$(HI_DIR)/%.hi-boot : $(OUT_DIR)/%.o-boot $(HI_DIR)
	@:

$(OHI_DIR)/%.hi-boot : $(OOUT_DIR)/%.o-boot $(OHI_DIR)
	@:

$(OUT_DIR)/%.o-boot: %.lhs-boot $(OUT_DIR)
	@echo compiling $< ...
	@$(HC) -c $< -i$(HI_DIR) -odir $(OUT_DIR) -hidir $(HI_DIR) $(HC_OPTS)

$(OUT_DIR)/%.o-boot: %.hs-boot $(OUT_DIR)
	@echo compiling $< ...
	@$(HC) -c $< -i$(HI_DIR) -odir $(OUT_DIR) -hidir $(HI_DIR) $(HC_OPTS)

$(OOUT_DIR)/%.o-boot: %.lhs-boot $(OOUT_DIR)
	@echo optimised compiling $< ...
	@$(HC) -c $< -i$(OHI_DIR) -odir $(OOUT_DIR) -hidir $(OHI_DIR) $(HC_OPTS) $(OFLAGS)

$(OOUT_DIR)/%.o-boot: %.hs-boot $(OOUT_DIR)
	@echo optimised compiling $< ...
	@$(HC) -c $< -i$(OHI_DIR) -odir $(OOUT_DIR) -hidir $(OHI_DIR) $(HC_OPTS) $(OFLAGS)


###################
# Haddock targets #
###################

# builds standard interface documentation
haddock : $(HADDOCK_DIR)
	@echo generating interface haddock ...
	@haddock -o $(HADDOCK_DIR) -h -t "Hsimp" $(USE_PKGS) $(filter-out %Raw.hs , $(SRCS))

# alias for haddock
doc : haddock
	@:
# builds an implementation documentation, i.e. including also elements that are not exported
haddock-impl : $(HADDOCK_IMPL_DIR)
	@echo generating implementation haddock ...
	@haddock -o $(HADDOCK_IMPL_DIR) -h --ignore-all-exports -t "Hsimp" $(USE_PKGS) $(filter-out %Raw.hs , $(SRCS))

# alias for haddock-impl
doc-impl : haddock-impl
	@:

########
# misc #
########

# builds directories
$(ALL_DIRS) : 
	@echo creating directory $@ ...
	@mkdir -p $@

# let ghc generate the dependencies
depend :
	@ghc -M -optdep-f -optdep.depend -odir $(OUT_DIR) -hidir $(HI_DIR) $(SRCS)
	@ghc -M -optdep-f -optdep.depend -odir $(OOUT_DIR) -hidir $(OHI_DIR) $(SRCS)

# include the result
-include .depend