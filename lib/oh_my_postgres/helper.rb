module OhMyPostgres
  module Helper
    def connect_db
      db_config = YAML.load_file('database.yml').fetch(ENV["DB"] || "postgres")
      ActiveRecord::Base.establish_connection(db_config)
      ActiveRecord::Schema.verbose = false

      db_logger(true)
      ActiveRecord::Base.connection.schema_cache.clear!

      migration_db if tables.size == 0
    end

    def db_logger(on)
      if on
        ActiveRecord::Base.logger = Logger.new(STDOUT) if defined?(Logger)
      else
        ActiveRecord::Base.logger = nil
      end
    end

    def migration_db
      DbMigration.up
    end

    def clear_db
      tables.each { |table| table.classify.constantize.send(:delete_all) }
    end

    def teardown_db
      tables.each do |table|
        ActiveRecord::Base.connection.drop_table(table)
      end
    end

    def reset_db
      teardown_db
      migration_db
    end

    def tables
      if ActiveRecord::VERSION::MAJOR >= 5
        ActiveRecord::Base.connection.data_sources
      else
        ActiveRecord::Base.connection.tables
      end
    end
  end
end
