class Conversation < ActiveRecord::Base
  self.table_name = :conversations

  has_many :messages
end