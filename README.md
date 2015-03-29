# Confluence Container for jenkins-ci.org

This container defines Confluence behind wiki.jenkins-ci.org.
The container consists of three main pieces:

* `/srv/wiki/base`: Upstream Confluence image. Ideally we don't want to touch this at all, unless we absolutely have to.
* `/srv/wiki/site`: Container local customizations to Confluence image. This also acts as `$CATALINA_BASE`
* `/srv/wiki/home`: Persisted portion of the Confluence data, such as attachments

The `site` portion includes our site-local customizations to Confluence, such as:

* Adjustment to JVM memory size
* Customized Tomcat configurations

## How to develop this container
You can start this container with mock LDAP and DB.

At the beginning of the development session, you do the following:

* `make startldap` to start a mock LDAP container in the background
* `make startdb` to start local mariadb container in the background.

At this point, if you have access to the backup of Confluence database and home, do the following optional steps.
Note that the backup database contains sensitive information, such as the password to access production LDAP,
security vulnerabilities, and so on. So it shouldn't be passed around casually:

* retrieve database dump as `backup.db.gz`
* `make restoredb` to fill DB with a copy of production data
* retrieve CONFLUENCE_HOME dump as `backup.fs.gz`
* 'tar xvzf backup.fs.gz` in the root of this Git repository

If you omit the above steps, Confluence will start empty, and you'll go through the setup wizard.

Finally, run `make run` to build and start Confluence container in the foreground.

When its initialization sequence is all done, point the browser to `http://localhost:8080/`.

Two valid users exist in mock LDAP container. 'kohsuke' and 'alice'.
'kohsuke' is a super user, 'alice' is a regular user. Password is both 'password'

To make changes to the Confluence container, press Ctrl+C to kill it,
make edits, and run `make run` again.

## Confluence Setup Wizard

Every time you start the container fresh (fresh db and `rm -rf ./data`), Confluence wants you to go
through the setup wizard.  When asked to configure database, choose "DataSource connection" and
type `java:comp/env/jdbc/wiki` as the value. This data source is configured to connect to local DB container.

If you've restored from dump, Confluence should skip the setup wizard.

Confluence is sensitive to the consistency of CONFLUENCE_HOME (in particular `./data/confluence.cfg.xml`)
and the database, and if they get out of sync, Confluence will refuse to come up. When this happens,
go back to clean slate by destroying Confluence and DB containers, `rm -rf ./data`, and start over.

Every time you go to the clean slate, Confluence will run the setup wizard, and this
process generates a new server ID, which means you have to request
a new evaluation license all the time. You can make this little easier by preseeding `./data/confluence.cfg.xml`
with the following content

    <confluence-configuration>
      <setupStep>setuplicense</setupStep>
      <setupType>initial</setupType>
      <buildNumber>0</buildNumber>
      <properties>
        <property name="confluence.setup.server.id">XXXX-XXXX-XXXX-XXXX</property>
        <property name="confluence.webapp.context.path"></property>
      </properties>
    </confluence-configuration>

... where `XXXX-XXXX-XXXX-XXXX` is the server ID. By fixing the server ID this way,
you can use the same evaluation license over and over.


## TODO
* oom_adj