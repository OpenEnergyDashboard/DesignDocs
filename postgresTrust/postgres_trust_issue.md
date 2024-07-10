# Postgres trust settings

[Issue #584](https://github.com/OpenEnergyDashboard/OED/issues/584) includes this work.

The current Postgres trust setting do not allow for the safest way to access the OED database.

In this file, it describes how to run script that will allow for updated postgres setting from the method ``trust`` to ``scram-sha-256``

When the database is opened, it will now prompt for the OED password, making this a much safer way to gain access to the database.

To do this, there must be a local terminal window opened up once [this script](./update_pg_conf.sh) is downloaded to the machine.

To make sure that this file is executable, run the command
``chmod +x update_pg_hba_conf.txt``

Following that, run the command ``./update_pg_hba_conf.txt``

The script will run a command asking you for the absolute path to the pg_hba.conf file installed within OED. Once that is entered, there is a sed script that will run and change the instances of ``trust`` into the updated version that is
``scram-sha-256.``

The last part of this script will involve restarting the postgres database, and this is done to ensure that the trust settings have been updated correctly. The script will cycle through three ways of how postgress waa installed to make sure that it restarts correctly. It goes through install helpers **brew, system, and service**. This should allow it to work for systems including, **MacOs, linux, unix, CentOS, as well as older linux and unix systems**.

This script should change the postgress trust settings to now be more secure.
