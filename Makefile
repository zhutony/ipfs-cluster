gx_version=v0.12.0
gx-go_version=v1.5.0

deptools=deptools

gx=gx_$(gx_version)
gx-go=gx-go_$(gx-go_version)
gx_bin=$(deptools)/$(gx)
gx-go_bin=$(deptools)/$(gx-go)
bin_env=$(shell go env GOHOSTOS)-$(shell go env GOHOSTARCH)
sharness = sharness/lib/sharness

export PATH := $(deptools):$(PATH)

all: service ctl
clean: rwundo clean_sharness
	$(MAKE) -C ipfs-cluster-service clean
	$(MAKE) -C ipfs-cluster-ctl clean

install: deps
	$(MAKE) -C ipfs-cluster-service install
	$(MAKE) -C ipfs-cluster-ctl install

build: deps
	go build -ldflags "-X ipfscluster.Commit=$(shell git rev-parse HEAD)"
	$(MAKE) -C ipfs-cluster-service build
	$(MAKE) -C ipfs-cluster-ctl build

service: deps
	$(MAKE) -C ipfs-cluster-service ipfs-cluster-service
ctl: deps
	$(MAKE) -C ipfs-cluster-ctl ipfs-cluster-ctl

$(gx_bin):
	@echo "Downloading gx"
	@mkdir -p ./$(deptools)
	@rm -f $(deptools)/gx
	@wget -nc -q -O $(gx_bin).tgz https://dist.ipfs.io/gx/$(gx_version)/$(gx)_$(bin_env).tar.gz
	@tar -zxf $(gx_bin).tgz -C $(deptools) --strip-components=1 gx/gx
	@mv $(deptools)/gx $(gx_bin)
	@ln -s $(gx) $(deptools)/gx
	@rm $(gx_bin).tgz

$(gx-go_bin):
	@echo "Downloading gx-go"
	@mkdir -p ./$(deptools)
	@rm -f $(deptools)/gx-go
	@wget -nc -q -O $(gx-go_bin).tgz https://dist.ipfs.io/gx-go/$(gx-go_version)/$(gx-go)_$(bin_env).tar.gz
	@tar -zxf $(gx-go_bin).tgz -C $(deptools) --strip-components=1 gx-go/gx-go
	@mv $(deptools)/gx-go $(gx-go_bin)
	@ln -s $(gx-go) $(deptools)/gx-go
	@rm $(gx-go_bin).tgz

gx: $(gx_bin) $(gx-go_bin)

deps: gx
	$(gx_bin) install --global
	$(gx-go_bin) rewrite

test: deps
	go test -tags silent -v ./...

test_sharness: $(sharness)
	@sh sharness/run-sharness-tests.sh

$(sharness):
	@echo "Downloading sharness"
	@wget -q -O sharness/lib/sharness.tar.gz http://github.com/chriscool/sharness/archive/master.tar.gz
	@cd sharness/lib; tar -zxf sharness.tar.gz; cd ../..
	@mv sharness/lib/sharness-master sharness/lib/sharness
	@rm sharness/lib/sharness.tar.gz

clean_sharness:
	@rm -rf ./sharness/test-results
	@rm -rf ./sharness/lib/sharness
	@rm -rf sharness/trash\ directory*

rw: gx
	$(gx-go_bin) rewrite
rwundo: gx
	$(gx-go_bin) rewrite --undo
publish: rwundo
	$(gx_bin) publish
.PHONY: all gx deps test test_sharness clean_sharness rw rwundo publish service ctl install clean
