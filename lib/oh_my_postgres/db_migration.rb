module OhMyPostgres
  class DbMigration < OhMyPostgres::MIGRATION_BASE_CLASS
    def self.up
      create_table :users
      create_table :conversations
      create_table :messages do |t|
        t.integer :conversation_id, null: false, index: true
        t.jsonb :read_status, default: {}
      end
      create_table :read_marks do |t|
        t.integer :user_id, null: false
        t.integer :message_id, null: false
        t.datetime :created_at
      end

      add_index :read_marks, [:user_id, :message_id], unique: true
    end

    def self.down
      drop_table :users
      drop_table :messages
      drop_table :read_marks
      drop_table :conversations
    end
  end
end
