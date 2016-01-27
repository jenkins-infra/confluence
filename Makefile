IMAGENAME=jenkinsciinfra/confluence
TAG=$(shell date '+%Y%m%d_%H%M%S')

image: build/wiki.docker

tag: image
	docker tag ${IMAGENAME} ${IMAGENAME}:${TAG}

clean:
	rm -rf build

startdb:
	@docker rm wiki-db || true
	# start a database instance
	docker run --name wiki-db -d -p 3306:3306 \
		-e MYSQL_ROOT_PASSWORD=s3cr3t \
		-e MYSQL_USER=wiki \
		-e MYSQL_PASSWORD=kiwi \
		-e MYSQL_DATABASE=wikidb \
		mariadb
    
restoredb:
	# restore dump from DB
	gunzip -c backup.db.gz | docker exec -i wiki-db mysql --user=wiki --password=kiwi wikidb
	# tweak database for test
	# cat tweak.sql | docker exec -i wiki-db mysql --user=wiki --password=kiwi wikidb

startldap:
	@docker rm ldap || true
	docker run -d --name ldap \
            -p 9389:389 jenkinsciinfra/mock-ldap

run: build/wiki.docker
	# start JIRA
	@docker rm wiki || true
	docker run -t -i --name wiki \
		--link wiki-db:db \
		--link ldap:ldap.jenkins-ci.org \
		-e PROXY_NAME=localhost \
		-e PROXY_PORT=8080 \
		-e PROXY_SCHEME=http \
		-e LDAP_PASSWORD=s3cr3t \
		-v `pwd`/data:/srv/wiki/home \
		-p 8080:8080 -e DATABASE_URL=mysql://wiki:kiwi@db/wikidb ${IMAGENAME}


build/wiki.docker: confluence/Dockerfile confluence/launch.bash $(shell find confluence/site/ -type f)
	@mkdir build 2> /dev/null || true
	docker build -t ${IMAGENAME} confluence
	touch $@

data:
	# extract dataset
	mkdir data
	cd data && tar xvzf ../backup.fs.gz
