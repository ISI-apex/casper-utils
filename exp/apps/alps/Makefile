CFLAGS+=$(shell /usr/bin/pkg-config --cflags --libs \
	cray-ugni cray-xpmem cray-alpsutil cray-alpslli \
	cray-udreg cray-wlm_detect cray-sysutils)

all: alpstest alpstestbare

alpstest:  alpstest.c
	mpicc -O0 -g $(CFLAGS) -o $@ $^

alpstestbare:  alps.c alpstestbare.c
	mpicc -O0 -g $(CFLAGS) -o $@ $^

clean:
	rm -f *.o alpstest alpstestbare
