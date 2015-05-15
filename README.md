# Announce

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](http://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.org/PRX/announce.svg?branch=master)](https://travis-ci.org/PRX/announce)
[![Code Climate](https://codeclimate.com/github/PRX/announce/badges/gpa.svg)](https://codeclimate.com/github/PRX/announce)
[![Coverage Status](https://coveralls.io/repos/PRX/announce/badge.svg)](https://coveralls.io/r/PRX/announce)
[![Dependency Status](https://gemnasium.com/PRX/announce.svg)](https://gemnasium.com/PRX/announce)

### Announce lets your services know about events, and helps you process them.

Announce is a gem to support using pub sub messages for events.

It is built on top of other job processors, like `shoryuken` to process the messages.
You can use ActiveJob classes to process the messages.

The basic purpose of it is to send event messages out from one of your services or applications, but without knowing who will receive it.  Then, other services can pick and choose which events to receive by subscribing to them, and having their workers perform work starting with those messages.

All events are structured as a combination of `subject` and `action`, and those values and the message itself are the required arguments for sending a message:
```ruby
# You can send a message from the Announce module directly
Announce.publish(:story, :publish, id: story.id)

# There is also a module to make this slightly easier
class SomeController
  include Announce::Publisher

  def create
    publish(:some, :create, id: @some.id)
  end
end
```

The message should be simple data, (json comaptible), and be something simple that any receiver can parse and understand.
This may be going to a receiver in a different programming language, so keep it generic.

If you are also building a ruby app/service to receive a message using `announce`, you can use a job class as you would for ActiveJob by also making it a subscriber to announcements:

```
require 'announce'

class SomeCreateJob < ActiveJob::Base
  include Announce::Subscriber

  subscribe_to :some, [:action]
end
```

The `announce` gem uses adapters so different message brokers can be used, but currently only has `shoryuken` for production, an `inline` adapter where messages are only processed synchronously and within the existing app, and a `test` adapter useful for stubbing out messaging sending and receiving.

The `shoryuken` adapter uses a combination of SNS and SQS for message handling, and includes a `rake` task to create the required SNS topics, SQS queues, and subscriptions between the two.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'shoryuken'
gem 'announce'
```

(The only interesting adapter at the moment is shoryuken, so you'll probably want to use that.)

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install announce shoryuken

## Configuration

Announce is configured 3 ways:

### Existing defaults are used if there is an ActiveJob configuration

If you are using `announce` with Rails 4.2 and ActiveJob, add the following lines to your `config/application.rb` file:
```ruby
    config.active_job.queue_adapter = :shoryuken
    config.active_job.queue_name_prefix = Rails.env
    config.active_job.queue_name_delimiter = '_'
```

You can set these values in announce itself, but if they are already in your application configuration, there's no reason to duplicate.

###  `subscribe_to` calls in your job classes

These method calls are used to configure `shoryuken` in two ways.

It adds the queues related to these subscriptions to the shoryuken worker process, so that process will request new messages for these subscriptions.

It also registers that the class calling subscribe should receive the announcements for this subscription.


### An `announce.yml` config file

You can specify a different location, but by default `announce` will load a config file from `config/announce.yml`.

This file allows you to set all the configuration for announce.
The most important aspects are specifying what subjects and actions your app will send and receive, and the namespacing for your topics, queues, and subscriptions.

This file is what is used for configuring SNS/SQS, it is not used to specify what queues shoryuken listens to, that is done with class methods in the jobs.

Here is a documented example `announce.yml` file:
```yaml
################################################################################
# `app_name`
# short name of this application or service
# limit to characters friendly to SQS, it will be used in creating queue names
################################################################################
app_name: my_app

################################################################################
# `adapter`
# which messaging adapter to use
# if unspecified, will use `config.active_job.queue_adapter` or 'inline'
################################################################################
adapter: shoryuken

################################################################################
# `publish`
# subject keys with action list values for announcements this app will make
# each subject must have at least one action.
################################################################################
publish:
  foo:
    - create

################################################################################
# `subscribe`
# subject keys with action list values for announcements received by the app
# each subject must have at least one action.
################################################################################
subscribe:
  bar:
    - delete

################################################################################
# `queues`
# shoryuken adapter only, parameters SQS creating SQS queues
# below are the default values for each parameter
################################################################################
queues:
  VisibilityTimeout: 3600
  DelaySeconds: 0
  MaximumMessageSize: 262144
  VisibilityTimeout: 3600
  ReceiveMessageWaitTimeSeconds: 0
  MessageRetentionPeriod: 604800
```

## Usage

### Configuring the Broker

To create the needed queues, topics, and subscriptions, first configure the `announce.yml` file, then run this rake task:
```
> bundle exec rake announce:configure_broker
```

If you are not using Rails, you can call the broker configuration from Ruby:
```ruby
Announce.configure(config_file: '/path/to/config/file/announce.yml')
Announce.configure_broker
```

### Sending

To send a message, the topics need to exists, so the broker must have been configured as per above.

An announcement is made using the `publish` method (also aliased as `announce`).
It take the 3 required params for `subject`, `action`, and the message `body`, and an optional `options` hash.

```ruby
# `publish` (or `announce`)
# subject - the type of entity that this event relates to
# action - the action that has occurred related to the entity
# body - the message body that will be sent out
# options (optional) - a hash of options to affect the publish, currently unused.
#
Announce.publish(:story, :publish, id: story.id, {})
Announce.announce(:story, :publish, id: story.id, {})
```

There is also a module you can include to get `publish` and `announce` methods:
```
class SomeController
  include Announce::Publisher

  def create
    @some = Some.new(some_params)
    @some.save!

    # announce it!
    publish(:some, :create, id: @some.id)
    respond_with(@some)
  end
end
```

As said above, the message `body` should be simple, serializable data, (json comaptible), and be something simple that any receiver can parse and understand.

Unlike other job libraries which specify the Ruby `Class` for processing as part of the message, these announcements meant to be decoupled - the sender should make no assumptions about the receiving application(s).


### Processing

To designate that a Ruby class will process a message, you must include the `Announce:Subscriber` module and call `subscribe_to` class method.

```
require 'announce'

class SomeCreateJob < ActiveJob::Base
  include Announce::Subscriber

  subscribe_to :some, [:create]

  def receive_some_create(message)
    do_something(message[:id])
  end
end
```

This works because the `Announce::Subscriber` adds the `subscribe_to` class method, but also a default `perform(*args)` instance method that delegates message handling to a job instance method named `"receive_#{subject}_#{action}"`.

The `announce` gem relies on other libraries to actual handle receiving messages and calling the worker class to process them.

For `shoryuken`, `subscribe_to` registers the worker for the appropriate queue, and also adds the queue to the list that will be polled by the shoryuken worker process (i.e. you don't need to add the queue to the `config/shoryuken.yml` file, or the command line call).  When starting up the shoryuken process, it should start retrieving messages on the appropriate queues without further shoryuken config.

```
# use -R to load the Rails application
# use -r <path to load> to load your workers if not in a Rails app
> bundle exec shoryuken -R
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/announce/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
