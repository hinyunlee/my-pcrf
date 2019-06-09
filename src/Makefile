ERLC = erlc
EBIN = ../ebin
INCLUDE = config.hrl dict/diameter_3gpp_gx.hrl
SRC = server.erl server_cb.erl session_db.erl
BEAMS = $(SRC:%.erl=$(EBIN)/%.beam)

all: pre-build $(BEAMS)

pre-build:
	make -C dict

$(EBIN)/%.beam: %.erl $(INCLUDE)
	$(ERLC) -Wall +debug_info -o $(EBIN) $<

clean:
	make -C dict clean
	rm -f $(BEAMS)
