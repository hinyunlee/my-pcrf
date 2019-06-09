ERLC = erlc
DIAC = /usr/lib64/erlang/lib/diameter-0.10/bin/diameterc
EBIN = ../../ebin
DICTS = diameter_3gpp_gx.dia
BEAMS = $(DICTS:%.dia=$(EBIN)/%.beam)

all: $(BEAMS)

$(EBIN)/%.beam: %.erl
	$(ERLC) -Wall +debug_info -o $(EBIN) $<

%.erl: %.dia
	$(DIAC) -i /usr/lib64/erlang/lib/diameter-0.10/ebin/ $<

clean:
	rm -f $(BEAMS) $(DICTS:%.dia=%.hrl)
