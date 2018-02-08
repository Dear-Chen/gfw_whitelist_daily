#!/bin/bash -xe

function setup() {
	export TZ=Asia/Shanghai
	git config --global user.name "Travis CI"
	git config --global user.email "travis.ci.build@gmail.com"
	git config --global log.date iso
}

function build() {
	# chnroute
	mkdir -p build/chnroute
	pushd build/chnroute
	> chnroute.txt
	curl -kL 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > chnroute.txt
	popd

	# dnsmasq rules
	mkdir -p build/dnsmasq
	pushd build/dnsmasq
	> adblock.conf
	echo -e "#\n# easylistchina+easylist\n#" >> adblock.conf
	curl -kL https://easylist-downloads.adblockplus.org/easylistchina+easylist.txt | grep ^\|\|[^\*]*\^$ | sed -e 's:||:address\=\/:' -e 's:\^:/127\.0\.0\.1:' >> adblock.conf
	echo -e "\n\n" >> adblock.conf
	echo -e "#\n# ABP-FX\n#" >> adblock.conf
	curl -kL https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/ABP-FX.txt | grep ^\|\|[^\*]*\^$ | sed -e 's:||:address\=\/:' -e 's:\^:/127\.0\.0\.1:' >> adblock.conf
	echo -e "\n\n" >> adblock.conf
	echo -e "#\n# custom rules\n#" >> adblock.conf
	curl -kL https://pexcn.github.io/dnsmasq-rules/rules.conf >> adblock.conf
	popd
}

function release() {
	git clone https://github.com/pexcn/daily.git -b gh-pages release --depth 5
	pushd release
	rm -r *
	cp -r ../build/* .
	git add --all
	git commit -m "[AUTO BUILD] `date +'%Y-%m-%d %T'`"
	git push --quiet "https://${token}@github.com/pexcn/daily.git" HEAD:gh-pages
	popd
}

setup
build
release