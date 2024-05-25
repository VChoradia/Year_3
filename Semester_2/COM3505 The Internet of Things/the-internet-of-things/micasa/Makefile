###########################################################################
# Mi Casa build
###########################################################################

# base config
PUBLISHABLE=12
TIOTDIR=$$HOME/the-internet-of-things
BUILD = build
MAKEFILE = Makefile
OUTPUT_FILENAME = book
METADATA = metadata.yml
CHAPTERS=$(shell ls [0-9]*.mkd)
#APPENDICES=$(shell for f in `ls A[0-9]*.mkd`; do echo -n "-A $${f} "; done)
APPENDICES=$(shell ls A[0-9]*.mkd)
TOC = --toc --toc-depth=4
METADATA_ARGS = --metadata-file=$(METADATA)
IMAGES_FOLDER = images
IMAGES = $(IMAGES_FOLDER)/*
COVER_IMAGE = $(IMAGES_FOLDER)/cover.png
MATH_FORMULAS = --webtex
CSS_FILE = style.css
CSS_ARGS = --css=$(CSS_FILE)
# DEBUG_ARGS = --verbose
PANDOC_COMMAND = pandoc

# version
#NUMCOMMITS=$(shell expr `git rev-list --count HEAD` + 787 )
NUMCOMMITS=$(shell expr `wget -q -O - \
    https://gitlab.com/hamishcunningham/the-internet-of-things | \
    grep 'project-stat-value[^C]*Commits' | \
    sed -e 's,.*project-stat-value">,,' -e 's,</strong> Comm.*,,' \
  ` + 787)
MAJOR=7
MINOR=$(NUMCOMMITS)
PATCH=$(shell date --iso-8601)
STATUS=
VERSION=$(MAJOR).$(MINOR).$(PATCH)

# combined args
LOCAL_ARGS = -s -f markdown+pipe_tables -F pandoc-crossref --citeproc \
  --number-sections --bibliography=paperpile.bib --strip-comments
ARGS = $(LOCAL_ARGS) $(TOC) $(MATH_FORMULAS) $(CSS_ARGS) $(METADATA_ARGS) \
  $(FILTER_ARGS) $(DEBUG_ARGS)

# per-format options
EPUB_ARGS = --epub-cover-image=$(COVER_IMAGE)
HTML_ARGS = --standalone --to=html5
PDF_ARGS = --template=eisvogel.latex -V geometry:margin=1in \
  -M documentclass:book -M titlepage:true --pdf-engine=xelatex \
  --top-level-division=chapter -V lang=en-GB --listings
DOCX_ARGS =


###########################################################################
# basic actions
###########################################################################

default: pdf html

book:	html pdf epub docx

clean:
	rm -r $(BUILD)

book.tex:
	$(PANDOC_COMMAND) $(ARGS) $(PDF_ARGS) -o build/$@ $(CHAPTERS) $(APPENDICES)


###########################################################################
# gitlab pages and CI/CD
###########################################################################

# update the metadata version number
setversion:
	sed -i 's!\(date: "Iteration .*\),.*!\1, $(VERSION))."!' metadata.yml

# deploy to gitlab pages
# note that we add script to do redirect if we're not on iot.unphone.net to
# avoid publishing at both gitlab.io and iot.unphone.net
deploy: updatepandoc setversion
	PATH="build/pandoc-2.11.3.2/bin:build:$$PATH" make
	sed -i '/^<head>$$/a <script> if(window.location.hostname != "iot.unphone.net") { window.location = "https://iot.unphone.net" } </script>' micasa-su-botnet.html
	sed -i 's,\(PDF version</a>; \),\1 <a href="/">navigation</a>; ,' micasa-su-botnet.html
	cp micasa-su-botnet.html ../public/plain-index.html
	sed -i '/^<head>$$/a <script src="script.js"></script>' micasa-su-botnet.html
	sed -i 's,<a href="/">navigation,<a href="plain-index.html">plain HTML,' micasa-su-botnet.html
	sed -i 's,^\(Copyright .*Hamish Cunningham.*\)</p>,\1 (.js: Christan Hare.)</p>,' micasa-su-botnet.html
	cp micasa-su-botnet.html ../public/index.html
	cp -a micasa-su-botnet.pdf images icons style.css script.js ../public

# install recent pandoc (e.g. into docker image)
updatepandoc:
	mkdir -p build; cd build; \
	wget https://github.com/jgm/pandoc/releases/download/2.11.3.2/pandoc-2.11.3.2-linux-amd64.tar.gz; \
	tar xzf pandoc-2.11.3.2-linux-amd64.tar.gz; \
	wget https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.9.0a/pandoc-crossref-Linux.tar.xz; \
        tar xJf pandoc-crossref-Linux.tar.xz; \
        ls -l

# create html and pdf artifacts on CI
ci-artifacts: updatepandoc
	PATH="build/pandoc-2.11.3.2/bin:build:$$PATH" make

# download the latest artifacts from CI (using an existing authenticated
# session in chrome)
get-ci-artifacts:
	rm ~/Downloads/artifacts.zip || :
	wget "https://gitlab.com/hamishcunningham/the-internet-of-things/-/jobs/artifacts/master/download?job=pages"
	while [ ! -f artifacts.zip ]; do sleep 2; done
	unzip -o artifacts.zip
	git status


###########################################################################
# file builders
###########################################################################

epub:	$(BUILD)/epub/$(OUTPUT_FILENAME).epub

PDFLINK = <a href="micasa-su-botnet.pdf">PDF version</a>; <a href="https://unphone.net">unphone.net</a>
html:	$(BUILD)/html/$(OUTPUT_FILENAME).html
	cp $< micasa-su-botnet.html
	sed -i 's,\(ate">Iteration.*\))\.</p>,\1; $(PDFLINK)).<br/>,' micasa-su-botnet.html
	RIGHTS=`grep '^rights: ' metadata.yml |sed -e 's,rights: ,,' -e 's,",,g'`; \
	sed -i \
          -e '/class="date">Iteration .*/ a '"$$RIGHTS </p>" \
          -e 's,\(<p class="author">Hamish Cunningham\),\1 <br/><small><i>(with Gareth Coleman and Valentin Radu)</i></small>,' \
          micasa-su-botnet.html

pdf:	$(BUILD)/pdf/$(OUTPUT_FILENAME).pdf
	cp $< micasa-su-botnet.pdf

docx:	$(BUILD)/docx/$(OUTPUT_FILENAME).docx

$(BUILD)/epub/$(OUTPUT_FILENAME).epub: \
  $(MAKEFILE) $(METADATA) $(CHAPTERS) $(CSS_FILE) $(IMAGES) $(COVER_IMAGE)
	mkdir -p $(BUILD)/epub
	$(PANDOC_COMMAND) $(ARGS) $(EPUB_ARGS) -o $@ $(CHAPTERS) $(APPENDICES)
	@echo "$@ was built"

$(BUILD)/html/$(OUTPUT_FILENAME).html: \
  $(MAKEFILE) $(METADATA) $(CHAPTERS) $(CSS_FILE) $(IMAGES)
	mkdir -p $(BUILD)/html
	$(PANDOC_COMMAND) $(ARGS) $(HTML_ARGS) -o $@ $(CHAPTERS) $(APPENDICES)
	rm -rf $(BUILD)/html/$(IMAGES_FOLDER)/
	cp -a $(IMAGES_FOLDER)/ $(BUILD)/html/$(IMAGES_FOLDER)/
	cp $(CSS_FILE) $(BUILD)/html/$(CSS_FILE)
	@echo "$@ was built"

$(BUILD)/pdf/$(OUTPUT_FILENAME).pdf: \
  $(MAKEFILE) $(METADATA) $(CHAPTERS) $(CSS_FILE) $(IMAGES) eisvogel.latex
	mkdir -p $(BUILD)/pdf
	$(PANDOC_COMMAND) $(ARGS) $(PDF_ARGS) -o $@ $(CHAPTERS) $(APPENDICES)
	@echo "$@ was built"

$(BUILD)/docx/$(OUTPUT_FILENAME).docx: \
  $(MAKEFILE) $(METADATA) $(CHAPTERS) $(CSS_FILE) $(IMAGES)
	mkdir -p $(BUILD)/docx
	$(PANDOC_COMMAND) $(ARGS) $(DOCX_ARGS) -o $@ $(CHAPTERS) $(APPENDICES)
	@echo "$@ was built"

old-style.css:
	echo '/* style.css */' > $@
	for f in bootstrap.united.min.css font-awesome.min.css \
          pygments/native.css style.css ; \
        do \
          cat ~/remaker/theming/pelican-bootstrap3/static/css/$${f} >>$@; \
        done
	sed -i \
          -e 's,text-decoration:none,text-decoration:underline,g' \
          -e 's,text-decoration: none,text-decoration: underline,g' \
          $@

ver:
	@echo $(VERSION)

contents:
	@I=0; \
        head -2 *--*mkd|grep -v '^$$'|grep -v '==' |while read -r l; \
        do \
          I=$$(($$I + 1)); \
          echo "$${l}\n" |sed 's,^#,'$$(printf "%02d" $$I)',' | \
            grep --color=always ' .* '; \
        done
