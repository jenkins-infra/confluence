IMAGENAME=jenkinsciinfra/confluence
TAG=$(shell date '+%Y%m%d_%H%M%S')

image: build/confluence.docker

tag: image
	docker tag ${IMAGENAME} ${IMAGENAME}:${TAG}

push :
	docker push ${IMAGENAME}

clean:
	rm -rf build

startdb:
	# start a database instance
	sudo docker run --name wiki-db -d -p 3306:3306 \
		-e MYSQL_ROOT_PASSWORD=s3cr3t \
		-e MYSQL_USER=wiki \
		-e MYSQL_PASSWORD=kiwi \
		-e MYSQL_DATABASE=wikidb \
		mariadb
    
restoredb:
	# restore dump from DB
	gunzip -c backup.db.gz | sudo docker exec -i wiki-db mysql --user=wiki --password=kiwi wikidb
	# tweak database for test
	cat tweak.sql | sudo docker exec -i wiki-db mysql --user=wiki --password=kiwi wikidb

startldap:
	@sudo docker rm ldap || true
	sudo docker run -d --name ldap \
            -p 9389:389 jenkinsciinfra/mock-ldap

run: build/wiki.docker
	# start JIRA
	@sudo docker rm wiki || true
	sudo docker run -t -i --name wiki \
		--link wiki-db:db \
		--link ldap:ldap.jenkins-ci.org \
		-e PROXY_NAME=localhost \
		-e PROXY_PORT=8080 \
		-e PROXY_SCHEME=http \
		-e LDAP_PASSWORD=s3cr3t \
		-v `pwd`/data:/srv/wiki/home \
		-p 8080:8080 -e DATABASE_URL=mysql://wiki:kiwi@db/wikidb ${IMAGENAME}


build/wiki.docker: confluence/Dockerfile confluence/launch.bash $(shell find confluence/site/ -type f)
	@mkdir build || true
	sudo docker build -t ${IMAGENAME} confluence
	touch $@

data:
	# extract dataset
	mkdir data
	cd data && tar xvzf ../backup.fs.gz
