# contrib/pg_variables/Makefile

MODULE_big = pg_variables
OBJS = pg_variables.o pg_variables_record.o $(WIN32RES)

EXTENSION = pg_variables
EXTVERSION = 1.2
DATA = pg_variables--1.0.sql pg_variables--1.0--1.1.sql pg_variables--1.1--1.2.sql
DATA_built = $(EXTENSION)--$(EXTVERSION).sql

PGFILEDESC = "pg_variables - sessional variables"

REGRESS = pg_variables pg_variables_any pg_variables_trans pg_variables_atx \
		pg_variables_atx_pkg

ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = contrib/pg_variables
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif

$(EXTENSION)--$(EXTVERSION).sql: $(DATA)
	cat $^ > $@
