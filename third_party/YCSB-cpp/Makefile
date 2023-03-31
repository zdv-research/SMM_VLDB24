#
#  Makefile
#  YCSB-cpp
#
#  Copyright (c) 2020 Youngjae Lee <ls4154.lee@gmail.com>.
#  Copyright (c) 2014 Jinglei Ren <jinglei@ren.systems>.
#


#---------------------build config-------------------------

DEBUG_BUILD ?= 0

# BIND_LEVELDB ?= 1
# EXTRA_CXXFLAGS ?= -I../leveldb/include
# EXTRA_LDFLAGS ?= -L../leveldb/build -lsnappy

BIND_LEVELDB ?= 1
EXTRA_CXXFLAGS ?= -I../leveldb_tpmm/include
EXTRA_LDFLAGS ?= -L../leveldb_tpmm/build -lsnappy

# BIND_LMDB ?= 1
# EXTRA_CXXFLAGS ?= -I../lmdb/libraries/liblmdb
# EXTRA_LDFLAGS ?= -L../lmdb/libraries/liblmdb -ldl -lz -lsnappy

# BIND_LMDB ?= 1
# EXTRA_CXXFLAGS ?= -I../lmdb_tpmm/libraries/liblmdb
# EXTRA_LDFLAGS ?= -L../lmdb_tpmm/libraries/liblmdb -lsnappy


BIND_ROCKSDB ?= 0
BIND_LMDB ?= 0

#----------------------------------------------------------

ifeq ($(DEBUG_BUILD), 1)
	CXXFLAGS += -g
else
	CXXFLAGS += -O2
	CPPFLAGS += -DNDEBUG
endif

ifeq ($(BIND_LEVELDB), 1)
	LDFLAGS += -lleveldb
	SOURCES += $(wildcard leveldb/*.cc)
endif

ifeq ($(BIND_ROCKSDB), 1)
	LDFLAGS += -lrocksdb
	SOURCES += $(wildcard rocksdb/*.cc)
endif

ifeq ($(BIND_LMDB), 1)
	LDFLAGS += -llmdb
	SOURCES += $(wildcard lmdb/*.cc)
endif

CXXFLAGS += -std=c++17 -Wall -pthread $(EXTRA_CXXFLAGS) -I./
LDFLAGS += $(EXTRA_LDFLAGS) -lpthread
SOURCES += $(wildcard core/*.cc)
OBJECTS += $(SOURCES:.cc=.o)
DEPS += $(SOURCES:.cc=.d)
EXEC = ycsb

all: $(EXEC)

$(EXEC): $(OBJECTS)
	@$(CXX) $(CXXFLAGS) $^ $(LDFLAGS) -o $@
	@echo "  LD      " $@

.cc.o:
	@$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<
	@echo "  CC      " $@

%.d : %.cc
	@$(CXX) $(CXXFLAGS) $(CPPFLAGS) -MM -MT '$(<:.cc=.o)' -o $@ $<

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif

clean:
	find . -name "*.[od]" -delete
	$(RM) $(EXEC)

.PHONY: clean
