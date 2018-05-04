require 'benchmark/ips'
require 'activerecord-import'
require 'colorize'

module OhMyPostgres
  module Experiment
    def setup_data(num_of_users: 100, num_of_conversations: 500, num_of_messages: 1000)
      num_of_users.times { User.create }
      num_of_conversations.times { Conversation.create }
      now = Time.current.to_s(:db)

      index, counter = 0, 0
      messages, read_marks = [], []
      while counter < num_of_messages
        user_id = rand(1..num_of_users)
        conversation_id = rand(1..num_of_conversations)
        messages << Message.new(read_status: { user_id.to_s => now }, conversation_id: conversation_id)
        read_marks << ReadMark.new(user_id: user_id, message_id: counter + 1)
        index += 1
        counter += 1

        if index == 1000
          Message.import messages
          ReadMark.import read_marks
          messages, read_marks = [], []
          index = 0
        end
      end

      if index > 0
        Message.import messages
        ReadMark.import read_marks
      end
    end

    def read_experiment
      db_logger false

      user = User.find(rand(1..100))
      conversation = Conversation.find(rand(1..500))
      puts "User id: #{user.id}".green
      puts "Conversation id: #{conversation.id}".green
      puts "#{conversation.messages.json_read_by(user).count} read messages in total #{Message.count} messages".green

      Benchmark.ips do |x|
        x.report('json_read_by') { conversation.messages.json_read_by(user).count }
        x.report('join_read_by') { conversation.messages.join_read_by(user).count }
        x.compare!
      end
    end

    def unread_experiment
      db_logger false

      user = User.find(rand(1..100))
      conversation = Conversation.find(rand(1..500))
      puts "User id: #{user.id}".green
      puts "Conversation id: #{conversation.id}".green
      puts "#{conversation.messages.json_unread_by(user).count} unread messages in total #{Message.count} messages".green

      Benchmark.ips do |x|
        x.report('json_unread_by') { conversation.messages.json_unread_by(user).count }
        x.report('join_unread_by') { conversation.messages.join_unread_by(user).count }
        x.compare!
      end
    end

    def mark_as_read_experiment
      user1 = User.find(rand(1..100))
      user2 = User.find(rand(1..100))
      puts "Mark 1000 messages read by user".green

      message_ids = (1..1000).to_a
      json_mark_as_read_raw = Benchmark.ms { Message.json_mark_as_read_raw(message_ids: message_ids, user: user1) }
      json_mark_as_read = Benchmark.ms { Message.json_mark_as_read(message_ids: message_ids, user: user2) }

      puts "json_mark_as_read_raw_sql: #{json_mark_as_read_raw}".light_cyan
      puts "json_mark_as_read: #{json_mark_as_read}".light_cyan
    end
  end
end
