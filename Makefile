# Compile flags and options follow.  The ones that aren't standard are documented 
# at the end of this file.  The first group MUST be set to get a working compile.

NAME = ncs5p

USE_F = yes
OPTIMIZE = yes
SYSTEM   = ethernet
#SYSTEM   = myrinet
#SYSTEM   = local

DEFINES  =
INCLUDES =
LIBS     =  -lm -lfl
YACC = bison -v -d -y
LEX  = flex

CFLAGS = $(ENVCFLAGS)
#CFLAGS += -g

# Special compile options begin here.

CFLAGS += -DUSE_FLOAT
#CFLAGS += -DSAME_PSC

#CFLAGS += -DMEM_STATS
#CFLAGS += -DMSG_STATS

USE_AIO = yes

QQ_ENABLE = no


ifeq ($(SYSTEM),local)
#  MPI = /usr/local/mpich-1.2.4
  MPI = /opt/mpich2
endif

ifeq ($(SYSTEM),myrinet)
#  MPI = /opt/mpich/myrinet/gnu
  MPI = /opt/mpich2
endif

ifeq ($(SYSTEM),ethernet)
#  MPI = /opt/mpich-1.2.7p1
#  MPI = /home/cthibeault/benchmarks/ncs_test_ompi_64bit/usr/ompi
  MPI = /usr/local
#  MPI = /opt/mpich/gnu
#  MPI = /opt/mpich2
  NAME = ncs5pe
endif

# The C compiler to use

CC  =  $(MPI)/bin/mpicc
CPP =  $(MPI)/bin/mpicxx

MPI_INCLUDES = -I$(MPI)/include
MPI_LIBPATH  = -L$(MPI)/lib

# The shell to use

RUN_SHELL = /bin/bash

# ----------------------------------------------------------------------------
# Compiler architecture & optimization flags 

# Architecture - Pentium Pro/Pentium II/Pentium III/Xeon/K6/K7/6x86mx

#CFLAGS  += -march=pentiumpro -march=i686 -mcpu=i686

#ifeq ( $(USE_F),yes )
#  CFLAGS  += -falign-functions=2 -falign-loops=2 -falign-jumps=2
#else
#  #CFLAGS  += -malign-functions=2 -malign-loops=2 -malign-jumps=2
#endif

# Optimization flags; these are very important

ifeq ($(OPTIMIZE),yes)
  CFLAGS += -O5 -finline-functions -ffast-math -funroll-loops \
            -fexpensive-optimizations
endif

CFLAGS += -Wunused -g

#---------------------------------------------------------------------------

INCLUDES += $(MPI_INCLUDES)
LIBS     +=  $(MPI_LIBS)
#LIBS     +=  parse/parse.a

OBJS = main.o NodeInfo.o Brain.o CellManager.o BuildBrain.o Connector.o Distributor.o   \
       Cell.o Compartment.o Channel.o ActiveSyn.o Synapse.o SynapseDef.o   \
       MessageManager.o MessageBus.o DoStim.o Stimulus.o DoReport.o Report.o   \
       RandomManager.o Random.o Output.o Input.o Port.o KillFile.o Memory.o \
       File.o Abort.o Options.o dprintf.o memstat.o CircleList.o SaveStruct.o LoadStruct.o \
       Augmentation.o SynapseToggle.o SynapseOverride.o

ifeq ($(QQ_ENABLE),yes)
  OBJS   += QQ.o
  CFLAGS += -DQQ_ENABLE
endif

ifeq ($(USE_AIO),yes)
  LIBS   += -lrt
  CFLAGS += -DUSE_AIO
endif


$(NAME): PARSER $(OBJS) Makefile
	@echo "doing main compile"
#	chmod u+x ncs kf
	$(CPP) -o $@ $(CFLAGS) $(OBJS) $(INCLUDES) parse/parse.a $(MPI_LIBPATH) $(LIBS)


# JF:  PARSER must be a target, so that the main make will execute a make in the
# parse directory to check for files that need to be built.


PARSER: 
	@echo "Making parse"
	cd parse; make parse.a "LIB = yes" "CFLAGS = $(CFLAGS) -D_IS_C" \
                        " MPI = ${MPI}"


#---------------------------------------------------------------------------------
# JF:  this is the start of the dependency list.  It's not complete (obviously), but
# I will add things as I'm working on them
# RPD:  Why not use makedepend instead?

main.o:                Brain.h Managers.h version.h BuildBrain.h RandomManager.h  \
                       DoStim.h DoReport.h KillFile.h defines.h parse/arrays.h    \
                       debug.h memstat.h

NodeInfo.o:            NodeInfo.h defines.h debug.h memstat.h

Brain.o:               Brain.h Managers.h Brain.h DoStim.h DoReport.h \
                       debug.h memstat.h 


CellManager.o:         CellManager.h Managers.h GCList.h parse/arrays.h

BuildBrain.o:          BuildBrain.h Managers.h SendList.h debug.h memstat.h

Distributor.o:         CellManager.h

Connector.o:           Managers.h RandomManager.h parse/arrays.h

Cell.o:                Cell.h Managers.h debug.h memstat.h

Compartment.o:         Compartment.h Managers.h ActiveSyn.h debug.h memstat.h

Channel.o:             Channel.h debug.h memstat.h

MessageManager.o:      MessageManager.h Message.h Packet.h defines.h memstat.h

MessageBus.o:          MessageBus.h Managers.h Message.h Packet.h defines.h

Synapse.o:             Synapse.h Managers.h InitStruct.h SynapseDef.h \
                       Random.h defines.h debug.h memstat.h


DoReport.o:            DoReport.h InitStruct.h RandomManager.h \
                       Report.h Managers.h GCList.h parse/arrays.h

DoStim.o:              DoStim.h InitStruct.h RandomManager.h \
                       Stimulus.h Managers.h GCList.h parse/arrays.h

Report.o:              Report.h Managers.h defines.h

Stimulus.o:            Stimulus.h Managers.h Message.h Random.h defines.h

Output.o:              Brain.h Report.h Managers.h Port.h defines.h parse/arrays.h

Input.o:               Brain.h Stimulus.h InputInfo.h Managers.h Port.h defines.h parse/arrays.h

Port.o:                Port.h

KillFile.o:            KillFile.h

#elements.o:            InitStruct.h

# dependencies of .h files

Brain.h:               defines.h Cell.h Stimulus.h Report.h SynapseDef.h


CellManager.h:         GCList.h parse/arrays.h


.SUFFIXES: .cpp .c .h .o

.cpp.o:
	  $(CPP) $(CFLAGS) -c $< $(ALL_INCLUDES)

.c.o:
	  $(CC) $(CFLAGS) -c $< $(ALL_INCLUDES)

.y.c:
	  bison  -d -o $@ $<

docs:
	cd documentation; make

codeDoc:
	./doc++ -d documentation/codeDoc Brain.h; tar -czf documentation/codeHtml.tgz documentation/codeDoc

server:
	cd voServer; make

serverDoc:
	cd voServer; ../doc++ -d ../documentation/serverDoc servermain.cpp

clean:
	rm -f ncs5p ncs5pe *.o core*; (cd parse; make clean)

# RPD:  Everything below this point is an experimental automated test suite.

# ncs5p-base is base binary, no smart
# ncs5p-smart is base binary with smart synapse
# ncs5p-smart2 is base binary with smart synapse and smart neg hebbian
# if user touches ncs5p, we assume we have to rebuild all test versions too

allbins:
	#mv -f ncs5p ncs5p.orig
	make clean; make -j 2
	cp ncs5p ncs5p-base
	make clean; make -j 2 ENVCFLAGS="-DRPD_SMART_SYNAPSE"
	cp ncs5p ncs5p-smart
	make clean; make -j 2 ENVCFLAGS="-DRPD_SMART_SYNAPSE -DRPD_SMART_NEGHEBB"
	cp ncs5p ncs5p-smart2
	touch allbins
	#mv -f ncs5p.orig ncs5p

test:	allbins
	#cp -f ncs5p ncs5p-orig
	chmod u+x ./ncs ./kf
# If we try to execute ncs from Makefile, mpi-launch will fail because
# the SHELL is set to /bin/sh (for some reason) and mpi-launch only
# likes SHELL to be csh, bash, tcsh.  So we create a subshell and reset
# the SHELL variable.  Can also pass it in on make command line.
	cp inputs/1column.in.compare-old .
#
	cp ncs5p-base ncs5p
	(export SHELL="/bin/bash"; ncs 1 1column.in.compare-old > nout-base-1proc)
	mv ReportLay1.txt ReportLay1.txt-base-1proc
	mv ReportLay2.txt ReportLay2.txt-base-1proc
	mv ReportLay3.txt ReportLay3.txt-base-1proc
#
	cp ncs5p-smart ncs5p
	(export SHELL="/bin/bash"; ncs 1 1column.in.compare-old > nout-smart-1proc)
	mv ReportLay1.txt ReportLay1.txt-smart-1proc
	mv ReportLay2.txt ReportLay2.txt-smart-1proc
	mv ReportLay3.txt ReportLay3.txt-smart-1proc
#
	cp ncs5p-smart2 ncs5p
	(export SHELL="/bin/bash"; ncs 1 1column.in.compare-old > nout-smart2-1proc)
	mv ReportLay1.txt ReportLay1.txt-smart2-1proc
	mv ReportLay2.txt ReportLay2.txt-smart2-1proc
	mv ReportLay3.txt ReportLay3.txt-smart2-1proc
#
# now test parallel:
#
	cp ncs5p-orig ncs5p
	(export SHELL="/bin/bash"; ncs 2 1column.in.compare-old > nout-smart2-2proc)
	mv ReportLay1.txt ReportLay1.txt-smart2-2proc
	mv ReportLay2.txt ReportLay2.txt-smart2-2proc
	mv ReportLay3.txt ReportLay3.txt-smart2-2proc
#
	(export SHELL="/bin/bash"; ncs 4 1column.in.compare-old > nout-smart2-4proc)
	mv ReportLay1.txt ReportLay1.txt-smart2-4proc
	mv ReportLay2.txt ReportLay2.txt-smart2-4proc
	mv ReportLay3.txt ReportLay3.txt-smart2-4proc
#
	(export SHELL="/bin/bash"; ncs 8 1column.in.compare-old > nout-smart2-8proc)
	mv ReportLay1.txt ReportLay1.txt-smart2-8proc
	mv ReportLay2.txt ReportLay2.txt-smart2-8proc
	mv ReportLay3.txt ReportLay3.txt-smart2-8proc
#
	@echo "If everything is OK, these diffs should produce no output:"
	diff3 ReportLay3.txt-base-1proc ReportLay3.txt-smart-1proc ReportLay3.txt-smart2-1proc | head
	diff3 ReportLay2.txt-base-1proc ReportLay2.txt-smart-1proc ReportLay2.txt-smart2-1proc | head
	diff3 ReportLay1.txt-base-1proc ReportLay1.txt-smart-1proc ReportLay1.txt-smart2-1proc | head
	diff --brief ReportLay3.txt-base-1proc ReportLay3.txt-smart2-2proc
	diff --brief ReportLay3.txt-base-1proc ReportLay3.txt-smart2-4proc
	diff --brief ReportLay3.txt-base-1proc ReportLay3.txt-smart2-8proc
#
	diff --brief ReportLay2.txt-base-1proc ReportLay2.txt-smart2-2proc
	diff --brief ReportLay2.txt-base-1proc ReportLay2.txt-smart2-4proc
	diff --brief ReportLay2.txt-base-1proc ReportLay2.txt-smart2-8proc
#
	diff --brief ReportLay1.txt-base-1proc ReportLay1.txt-smart2-2proc
	diff --brief ReportLay1.txt-base-1proc ReportLay1.txt-smart2-4proc
	diff --brief ReportLay1.txt-base-1proc ReportLay1.txt-smart2-8proc
#
#	@echo "Execution times (three Wall times:  init time, init + sim time, init + sim + cleanup):"
	@echo "Base version, no smart synapse:"
	@grep Wall nout-base-1proc
	@echo "Base version, just smart synapse:"
	@grep Wall nout-smart-1proc
	@echo "Smart synapse and smart neg Hebb, 1 processor:"
	@grep Wall nout-smart2-1proc
	@echo "Smart synapse and smart neg Hebb, 2 processors:"
	@grep Wall nout-smart2-2proc
	@echo "Smart synapse and smart neg Hebb, 4 processors:"
	@grep Wall nout-smart2-4proc
	@echo "Smart synapse and smart neg Hebb, 8 processors:"
	@grep Wall nout-smart2-8proc


#-------------------------------------------------------------------------
# Documentation of compile flags & options begins here

# The following flags control compile & linking.  They should be set to one
# of the allowed values to produce a good executable.  If they're changed, you
# should remove all .o files and do a full recompile.

# OPTIMIZE - Controls whether compiler optimization is used.  Should be "yes"

# SYSTEM - Controls which MPI version will be used.  May be "myrinet" or 
# "ethernet" on cortex.  There is also "local", which is for compiling on other
# systems.  Set the appropriate path under "ifeq ($(SYSTEM),local)".

# Enabling these options turns on useful features that are not activated
# by default for one or more of several reasons, including:  1) they can
# change the output, complicating results verification, 2) they are
# not ready for general use, but should be tracked in version control, 3)
# they compile in features used for testing or performance measurement which
# (for performance reasons) shouldn't be in the production version.

# In general, if you add an option here should make sure that when the 
# new option is not enabled the code that is compiled is a clean, functional
# version of the program without your new feature.  Thus if you need to
# verify output of the program with your modification with the base version
# you can compile once with your option enabled, save the binary, do a
# make clean and compile without your option, and compare the results of
# the two binaries.

# Please provide a description of the option here so that others can
# learn from and possibly use your option if it is useful.
# You should do a "make clean; make" (or erase affected .o files by hand) if
# you change any of these options, since there's no sort of dependency checking.

#----- Executable options ----------------------------------------------
# These produce different executables for different circumstances.  They should
# generally be turned on.

# USE_FLOAT - Compiles parts of the Synapse & related structures to use floats
# instead of doubles for many variables.  This considerably reduces the memory
# required.  (Doesn't seem to be a significant change in execution time.) (jf)

# USE_AIO - This will compile an executable that uses asynchronous I/O routines
# to write binary output files.  This is quite a bit faster than using standard
# fwrite.  It does not affect ASCII output at all. (jf)

# SAME_PSC - If all the PSC templates used are the same (which AFAIK has always 
# been true), then the Compartment::GetSynapseCurrent routine can be made to
# run significantly faster by combining all the PSCs received by a compartment
# at a particular timestep. (Just how much depends on the number of spikes 
# received.) (jf)

#----- Debugging & tracing options ------------------------------------------
# These produce executables with debugging & tracing options.  The info is 
# mostly useful to programmers, and may make the executables run slower.
# should generally be turned off.

# QQ_ENABLE - Includes the QQ precision timing library code (QQ.cpp).  This
# allows sections of code to be timed with a resolution of several tens of 
# nanoseconds. (jf)

# TRACE_FIRE - Adds code to output count of firings & spikes received at each
# timestep.  Useful only on a single-processor run, but might be handy for
# debugging brain models, to see if firing rates are biologically realistic. (jf)

# MSG_STATS - Compiles code into MessageBus that collects statistics on number
# of messages sent per timestep, time spent sending vs computation, time spent 
# in barrier synchronization, etc.  Do NOT compile in production code! (JF)

# MEM_STATS - Causes memory usage stats to be collected.  Do NOT compile in
# production code! (JF)


