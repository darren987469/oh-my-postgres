# OhMyPostgres

Notification system keep track of whether message is read by user. The relation DB design maybe something like:

TABLE `messages` | TABLE `read_marks` | TABLE `users`
-----------------|--------------------|-------------
{ id: 1 } | { message_id: 1, user_id: 1, created_at: '2018-01-01 10:00:00' } | { id: 1 }


A join table `read_marks` record whether user has read the message.

Postgres support json datatype since 9.3. There is another choice for us to use json to store read_mark. We can add a column named `read_status` with json type into `messages` table. The record would be

```ruby
# message
{ id: 1, read_status: { '1' => '2018-01-01 10:00:00' } }
```

There goes my question: which DB design is more efficiency for query and update? The join way or the json way?

The join way obviously create more table and records. It needs to join tables when query, and create records when record read status. The performance of json way may be low when to query or updates since postgres is a relational database. Let's do some benchmarks to answer the question.

## Benchmark

In the real world case, we may query what are the messages unread by the user in a conversation. So tables in database would be `users`, `conversations`, `messages`, `read_marks`. Conversation has many messages and many users participant in.

### Setup data

To generate data for experiment, use following command

```ruby
setup_data(num_of_users: 100, num_of_conversations: 500, num_of_messages: 100_000)
```

This would generate 100 users, 500 conversations, and 100,000 messages. Each message will assign to one conversation and mark as read by one user randomly. The read mark is store in `message.read_status` (json way) and an record in table `read_marks` (join way).

### Experiment1: unread message for user

Randomly select one user and one conversation, query unread message count of the user in that conversation.

```ruby
def unread_experiment
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

unread_experiment

# User id: 31
# Conversation id: 14
# 200 unread messages in total 100000 messages
# Warming up --------------------------------------
#       json_unread_by   149.000  i/100ms
#       join_unread_by    71.000  i/100ms
# Calculating -------------------------------------
#       json_unread_by      1.510k (± 1.3%) i/s -      7.599k in   5.032976s
#       join_unread_by    724.554  (± 1.2%) i/s -      3.692k in   5.096310s

# Comparison:
#       json_unread_by:     1510.1 i/s
#       join_unread_by:      724.6 i/s - 2.08x  slower
```

The result shows the join way is slower the the json way.

### Experiment2: read message for user

```ruby
read_experiment

# User id: 44
# Conversation id: 328
# 1 read messages in total 100000 messages
# Warming up --------------------------------------
#         json_read_by   150.000  i/100ms
#         join_read_by    79.000  i/100ms
# Calculating -------------------------------------
#         json_read_by      1.540k (± 1.5%) i/s -      7.800k in   5.067500s
#         join_read_by    815.640  (± 2.8%) i/s -      4.108k in   5.040683s

# Comparison:
#         json_read_by:     1539.6 i/s
#         join_read_by:      815.6 i/s - 1.89x  slower
```

### Conclusion

According to experiment results, the json way has better performance than the join way. That's a surprise! I originally consider the join way should be more fast.

The test data are not real word data, the result may not the same when apply to the real world.

### Bonus

Benchmark for update message.read_status with

option1: update row by row

```ruby
def self.json_mark_as_read(message_ids:, user:)
  now = Time.current.to_s(:db)
  user_id = user.id.to_s
  where(id: message_ids).find_each do |message|
    message.read_status[user_id] = now
    message.save!
  end
end
```

option2: update by raw sql

```ruby
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
```

Result:

```ruby
mark_as_read_experiment

# test with 1000 messages
# json_mark_as_read_raw_sql: 16.625999996904284
# json_mark_as_read: 2227.266999994754
```

## Installation

```shell
bundle
```

## Usage

run `bin/console` for an interactive prompt.

```ruby
# commands are in lib/oh_my_postgres/experiment.rb
setup_data(num_of_users: 100, num_of_conversations: 500, num_of_messages: 1000)
read_experiment
unread_experiment
mark_as_read_experiment

# db helper method, lib/oh_my_postgres/helper.rb
connect_db
db_logger false
clear_db
teardown_db
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/darren987469/oh_my_postgres.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
