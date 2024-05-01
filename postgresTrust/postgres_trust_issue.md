<h1><b>Postgres trust settings</b></h1>

The current Postgres trust setting do not allow for the safest way to access the OED database.

In this file, it descibes how to run script that will allow for updated postgres setting from the method <code>trust</code> to <code>scram-sha-256</code>

When the database is opened, it will now prompt for the OED password, making this a much safer way to gain access to the database.

To do this, there must be a local terminal window opened up once the file is downloaded to the machine.

To make sure that this file is executable, run the command
<code>chmod +x update_pg_hba_conf.txt</code>

Following that, run the command <code>./update_pg_hba_conf.txt</code>

The script will run a command asking you for the absolute path to the pg_hba.conf file installed within OED. Once that is entered, there is a sed script that will run and chnge the instances of <code>trust</code> into the updated version that is 
<code>scram-sha-256.</code>

The last part of this script will involve restarting the postgres database, and this is done to ensure that the trust settings have been updated correctly. The script will cycle through three ways of how postgress waa installed to make sure that it restarts correctly. It goes through install helpers <b>brew, system, and service</b>. This should allow it to work for systems including, <b>MacOs, linux, unix, CentOS, as well as older linux and unix systems. </b>

This script should change the postgress trust settings to now be more secure.
