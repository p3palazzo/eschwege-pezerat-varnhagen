# This Makefile provides sensible defaults for projects
# based on Pandoc and Jekyll, such as:
# - Dockerized runs of Pandoc and Jekyll with separate
#   variables for version numbers = easy update!
# - Lean CSL checkouts without committing to the repo
# - Website built on the gh-pages branch

# Global variables and setup {{{1
# ================
VPATH = _lib
vpath %.bib _bibliography
vpath %.csl .:_csl
vpath %.yaml .:_spec
vpath default.% .:_lib
vpath reference.% .:_lib

DEFAULTS := defaults.yaml references.bib
JEKYLL-VERSION := 4.2.0
PANDOC-VERSION := 2.14
JEKYLL/PANDOC := docker run --rm -v "`pwd`:/srv/jekyll" \
	-u "`id -u`:`id -g`" palazzo/jekyll-tufte:$(JEKYLL-VERSION)-$(PANDOC-VERSION)
PANDOC/CROSSREF := docker run --rm -v "`pwd`:/data" \
	-u "`id -u`:`id -g`" pandoc/crossref:$(PANDOC-VERSION)
PANDOC/LATEX := docker run --rm -v "`pwd`:/data" \
	-u "`id -u`:`id -g`" palazzo/pandoc-ebgaramond:$(PANDOC-VERSION)

# Targets and recipes {{{1
# ===================
%.pdf : %.md $(DEFAULTS) \
	| _csl/chicago-fullnote-bibliography-with-ibid.csl
	$(PANDOC/LATEX) -d _spec/defaults.yaml -o $@ $<
	@echo "$< > $@"

%.docx : %.md $(DEFAULTS) reference.docx \
	| _csl/chicago-fullnote-bibliography-with-ibid.csl
	$(PANDOC/CROSSREF) -d _spec/defaults.yaml -o $@ $<
	@echo "$< > $@"

.PHONY : _site
_site : | _csl/chicago-fullnote-bibliography-with-ibid.csl
	@$(JEKYLL/PANDOC) /bin/bash -c \
	"chmod 777 /srv/jekyll && jekyll build --future"

_csl/%.csl : | _csl
	@cd _csl && git checkout master -- $(@F)
	@echo "Checked out $(@F)."

# Install and cleanup {{{1
# ===================
.PHONY : _csl
_csl :
	@echo "Fetching CSL styles..."
	@test -e $@ || \
		git clone --depth=1 --filter=blob:none --no-checkout \
		https://github.com/citation-style-language/styles.git \
		$@

.PHONY : serve
serve : | _csl/chicago-fullnote-bibliography-with-ibid.csl
	docker run --rm -v "`pwd`:/srv/jekyll" \
		-p "4000:4000" -h "0.0.0.0:127.0.0.1" \
		palazzo/jekyll-tufte:$(JEKYLL-VERSION)-$(PANDOC-VERSION) \
		jekyll serve --future

.PHONY : clean
clean :
	-rm -rf _book/* _site _csl

# vim: set foldmethod=marker shiftwidth=2 tabstop=2 :
