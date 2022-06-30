.PHONY: test clean

OTHEROPTS = --auto-inline -Werror

RTSARGS = +RTS -M6G -A128M -RTS ${OTHEROPTS}

test:
	agda ${RTSARGS} -i. Everything.agda

html:
	agda ${RTSARGS} --html -i. Everything.agda

clean:
	find . -name '*.agdai' -exec rm \{\} \;
