#!/bin/bash
# Set up postgres db for local debugging.
# 
# Unlike MySQL, PostgreSQL makes it harder to set blank passwords or set
# passwords from the command line.
#
# See here for background:
# stackoverflow.com/questions/5421807/set-blank-password-for-postgresql-user
# dba.stackexchange.com/questions/14740/how-to-use-psql-with-no-password-prompt
# postgresql.1045698.n5.nabble.com/assigning-password-from-script-td1884293.html
#
# Thus what we'll do is use the .pgpass file as our single point of
# truth, for both setting up postgres and then accessing it later via
# sequelize. We can also symlink this file into the home directory.

# Install postgres
sudo apt-get install -y postgresql postgresql-contrib

# Symlink into home.
# Note the use of backticks, PWD, and the -t flag.
#
#* Create a symbolic link in our $HOME directory pointing to the .pgpass file in
#* the repo directory.  Make it read/writable only to owner.
ln -sf `ls $PWD/.pgpass` -t $HOME
chmod 600 $HOME"/.pgpass"

# Extract variables from the .pgpass file
# stackoverflow.com/a/5257398
# goo.gl/X51Mwz
#
#* bash black magic for tokenizing the contents of .pgpass, which is a string 
#* consisting of colon-separated values
PGPASS=`cat .pgpass`
TOKS=(${PGPASS//:/ })
PG_HOST=${TOKS[0]}
PG_PORT=${TOKS[1]}
PG_DB=${TOKS[2]}
PG_USER=${TOKS[3]}
PG_PASS=${TOKS[4]}

# Now set up the users
#
# If you don't type in the password right, easiest is to change the value in
# pgpass and try again. You can also delete the local postgres db
# if you know how to do that. 
#
#* Whereas we've previously used sudo to run commands as the linux superuser, in
#* this case, we use it to run the the following commands as the linux user named
#* "postgres".  The commands are postgres utility commands.  First, we create a
#* postgreSQL user role (note: *not* a linux user account) named "ubuntu", and
#* give it a password (bitstart0) and postgreSQL superuser status.  Next, we create
#* a postgreSQL database named "bitdb0", owned by the user role "ubuntu".
#* Got that?  We're using sudo to run postgres user & db creation commands as the
#* linux user "postgres".
echo -e "\n\nINPUT THE FOLLOWING PASSWORD TWICE BELOW: "${PG_PASS}
sudo -u postgres createuser -U postgres -E -P -s $PG_USER
sudo -u postgres createdb -U postgres -O $PG_USER $PG_DB

# Test that it works.
# Note that the symlinking of pgpass into $HOME should pass the password to psql and make these commands work. 
#
#* Now we use the "PostgreSQL interactive terminal" (psql) to run some commands on
#* the bitdb0 database, under the user role ubuntu.  psql picks up the necessary
#* host, port, and password info from the .pgpass file in our home directory (which
#* is symlinked to the one in our git repo.
#*
#* First we create a table "phonebook" with four columns: "phone", "firstname", 
#* "lastname", and "address" - each with a data type variable-length character string,
#* and maximum lengths given.
#*
#* Next we insert one row of data into the table, with the column values given.
#* The output of the INSERT command should be "0 1", where 1 is the number of rows
#* inserted, and 0 is the "OID" of the inserted row.  OIDs are automatically created
#* keys (think of it as an extra column containing row numbers - so we just inserted
#* the zero'th row).  However, since the data type of an OID (four-byte integer) is
#* not large enough to be unique for large data sets, using them for anything is 
#* discouraged:  http://www.postgresql.org/docs/8.0/static/datatype-oid.html
echo "CREATE TABLE phonebook(phone VARCHAR(32), firstname VARCHAR(32), lastname VARCHAR(32), address VARCHAR(64));" | psql -d $PG_DB -U $PG_USER
echo "INSERT INTO phonebook(phone, firstname, lastname, address) VALUES('+1 123 456 7890', 'John', 'Doe', 'North America');" | psql -d $PG_DB -U $PG_USER
