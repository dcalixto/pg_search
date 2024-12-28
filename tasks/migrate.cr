require "db"
require "pg"
require "micrate"

Micrate::DB.connection_url = "postgres://localhost/pg_search_test"
Micrate::Cli.run
