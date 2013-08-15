#!/bin/bash
# Install node packages
#
#* npm is the node.js package manager.
#* This command references the package.json file in the current directory.
#* Modules are installed to the node_modules directory.
#* In our case, package.json gives the following dependencies:
#*
#*  sequelize - maps javascript objects to MySQL/SQLite/PostgreSQL database 
#*  entries to provide easy access to the database.
#*  pg - PostgreSQL client for node.js
#*  ejs - Embedded JavaScript templates
#*  express - Sinatra inspired web development framework
#*  async - Higher-order functions and common patterns for asynchronous code
#
npm install

echo -e "\n\nNOW ENTER YOUR HEROKU PASSWORD"
# Set up heroku.
# - devcenter.heroku.com/articles/config-vars
# - devcenter.heroku.com/articles/heroku-postgresql
heroku login
#* Creates a new app on heroku, and adds a "heroku" remote in git
heroku create
#* Note that you don't have to create a new ssh key if you already have one
#* on your EC2 instance, and have registered it with "heroku keys:add"
ssh-keygen -t rsa
heroku keys:add
#* This adds the heroku postgres addon to your app.  The "dev" flavor is
#* a free version for testing and development:
#* https://devcenter.heroku.com/articles/heroku-postgres-plans#starter-tier
heroku addons:add heroku-postgresql:dev
#* When the postgres addon is added, heroku auto-magically sets up an initial
#* database for you.  Apps can have multiple databases, and the URLs 
#* specifying their locations are held in heroku config (environment) variables.  
#* The primary database is pointed to by the DATABASE_URL variable.  The 
#* auto-generated initial database has a variable that looks like 
#* "HEROKU_POSTGRESQL_COLOR_URL".  In my case the COLOR was PINK.  The command 
#* below "promotes" the initial database to primary by grepping & cutting the 
#* initial variable out of the heroku config, then feeding that variable name 
#* to "heroku pg:promote".  It's all a really roundabout way of updating an 
#* environment variable for your heroku app.
heroku pg:promote `heroku config  | grep HEROKU_POSTGRESQL | cut -f1 -d':'`
#* heroku-config is a plugin for the heroku toolbelt that provides commands to 
#* push/pull your heroku environment (e.g. DATABASE_URL) to and from your local 
#* working directory (the .env file).  heroku-config extends the "heroku config" 
#* command.  It is written in Ruby.
heroku plugins:install git://github.com/ddollar/heroku-config.git

# Set up heroku configuration variables
# https://devcenter.heroku.com/articles/config-vars
# - Edit .env to include your own COINBASE_API_KEY and HEROKU_POSTGRES_URL.
# - Modify the .env.dummy file, and DO NOT check .env into the git repository.
# - See .env.dummy for details.
#
#* Pretty well explained above.  .env is read by Foreman, which is heroku's
#* tool for running apps locally on your development machine.  heroku-config
#* is used to push and pull the contents of .env to your app's environment on
#* heroku's servers.  (Which is what the "heroku config" command prints out.)
cp .env.dummy .env

# For local: setup postgres (one-time) and then run the local server
#
#* See notes in the comments of pgsetup.
./pgsetup.sh

STRING=$( cat <<EOF
Great. You've now set up local and remote postgres databases for your
app to talk to.\n\n

Now do the following:\n\n

1) Get your API key from coinbase.com/account/integrations\n\n
2) Paste it into the .env file.\n\n
3) To run the server locally, do:\n
     $ foreman start\n
   Then check your EC2 URL, e.g. ec2-54-213-131-228.us-west-2.compute.amazonaws.com:8080 \n
   Try placing some orders and then clicking '/orders' at the top.\n\n
4) To deploy to heroku\n
     $ git push heroku master\n
     $ heroku config:push\n
   Then check the corresponding Heroku URL\n\n
   Try placing some orders and then clicking '/orders' at the top.\n
EOF
)
echo -e $STRING
