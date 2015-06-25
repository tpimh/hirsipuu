SRCS = hirsipuu.vala
PROGRAM = hirsipuu
VALAPKGS = --pkg sdl2 --pkg sdl2-ttf --vapidir=../sdl2-vapi
VALAOPTS =
CFLAGS = -X -lSDL2 -X -lSDL2_ttf

ifndef VALA_COLORS
	VALA_COLORS = "error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01"
	export VALA_COLORS
endif

ifndef GCC_COLORS
	GCC_COLORS = "error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01"
	export GCC_COLORS
endif

all: $(PROGRAM)

$(PROGRAM): $(SRCS)
	valac $(VALAOPTS) $(VALAPKGS) $(CFLAGS) -o $(PROGRAM) $(SRCS)

clean:
	rm -f $(PROGRAM)
