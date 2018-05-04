require 'active_record'

require 'oh_my_postgres/version'
require 'oh_my_postgres/models/user'
require 'oh_my_postgres/models/conversation'
require 'oh_my_postgres/models/message'
require 'oh_my_postgres/models/read_mark'
require 'oh_my_postgres/helper'
require 'oh_my_postgres/experiment'

OhMyPostgres::MIGRATION_BASE_CLASS = if ActiveRecord::VERSION::MAJOR >= 5
  ActiveRecord::Migration[5.0]
else
  ActiveRecord::Migration
end

require 'oh_my_postgres/db_migration'
