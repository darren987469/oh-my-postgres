class ReadMark < ActiveRecord::Base
  self.table_name = :read_marks

  belongs_to :user, class_name: 'User', foreign_key: :user_id
  belongs_to :message, class_name: 'Message', foreign_key: :message_id, inverse_of: :read_marks
end
