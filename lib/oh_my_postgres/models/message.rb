class Message < ActiveRecord::Base
  self.table_name = :messages

  has_many :read_marks, foreign_key: :message_id

  scope :join_unread_by, ->(user) { joins("LEFT JOIN read_marks ON read_marks.user_id = #{user.id} AND read_marks.message_id = messages.id").where(read_marks: { id: nil }) }
  scope :join_read_by, ->(user) { includes(:read_marks).references(:read_marks).where(read_marks: { user_id: user.id }) }

  scope :json_unread_by, ->(user) { where('(read_status -> ?) IS NULL', user.id.to_s) }
  scope :json_read_by, ->(user) { where('(read_status -> ?) IS NOT NULL', user.id.to_s) }

  def self.json_mark_as_read(message_ids:, user:)
    now = Time.current.to_s(:db)
    user_id = user.id.to_s
    where(id: message_ids).find_each do |message|
      message.read_status[user_id] = now
      message.save!
    end
  end

  def self.json_mark_as_read_raw(message_ids:, user:)
    now = Time.current
    sql = <<-sql
      UPDATE messages
      SET read_status = jsonb_set(read_status::jsonb, \'{#{user.id}}\', \'"#{now.to_s(:db)}"\', true)
      WHERE messages.id in (#{message_ids.join(', ')})
    sql
    ActiveRecord::Base.connection.execute(sql)
    self.where(id: message_ids)
  end
end
