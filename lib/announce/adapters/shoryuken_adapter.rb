require 'shoryuken'
require 'announce/adapters/base_adapter'

module Announce
  module Adapters
    class ShoryukenAdapter < BaseAdapter

      class Subscriber < BaseAdapter::Subscriber
        def subscribe(worker_class, subject, actions, options)
          Array(actions).each do |action|
            queue_name = Queue.name_for(subject, action)
            Shoryuken.register_worker(queue_name, worker_class, true)
          end
        end
      end

      class BrokerManager < BaseAdapter::BrokerManager

        # actually configure the broker queues, topics, and subscriptions
        def configure
          configure_publishing && configure_subscribing
        end

        def configure_publishing
          (options[:publish] || {}).each do |subject, actions|
            Array(actions).each do |action|
              ShoryukenAdapter::Topic.new(subject, action, options).create
            end
          end
          true
        end

        def configure_subscribing
          (options[:subscribe] || {}).each do |subject, actions|
            Array(actions).each do |action|
              topic = ShoryukenAdapter::Topic.new(subject, action, options)
              queue = ShoryukenAdapter::Queue.new(subject, action, options)
              topic.create
              queue.create
              topic.subscribe(queue)
            end
          end
          true
        end
      end

      class Topic < BaseAdapter::Topic

        def publish(message, options = {})
          Shoryuken::Client.topics(name).send_message(message, options)
        end

        def create
          sns.create_topic(name: name)[:topic_arn]
        end

        def subscribe(queue)
          subscription_arn = sns.subscribe(
            topic_arn: arn,
            protocol: 'sqs',
            endpoint: queue.arn
          )[:subscription_arn]

          sns.set_subscription_attributes(
            subscription_arn: subscription_arn,
            attribute_name: 'RawMessageDelivery',
            attribute_value: 'true'
          )
          subscription_arn
        end

        def arn
          account_id = Shoryuken::Client.account_id
          region = sns.config[:region]
          "arn:aws:sns:#{region}:#{account_id}:#{name}"
        end

        def sns
          Shoryuken::Client.sns
        end
      end

      class Queue < BaseAdapter::Queue

        def create
          create_attributes = default_options.merge((options[:queues] || {}).stringify_keys)

          dlq_arn = create_dlq
          create_attributes['RedrivePolicy'] = %Q{{"maxReceiveCount":"10", "deadLetterTargetArn":"#{dlq_arn}"}"}

          sqs.create_queue(queue_name: name, attributes: create_attributes)[:queue_url]
        end

        def arn
          account_id = Shoryuken::Client.account_id
          region = sqs.config[:region]
          "arn:aws:sqs:#{region}:#{account_id}:#{name}"
        end

        def create_dlq
          dlq_name = "#{name}_failures"

          dlq_options = {
            'MaximumMessageSize' => "#{(256 * 1024)}",
            'MessageRetentionPeriod' => "#{2 * 7 * 24 * 60 * 60}" # 2 weeks in seconds
          }

          dlq = sqs.create_queue(
            queue_name: dlq_name,
            attributes: dlq_options
          )

          attrs = sqs.get_queue_attributes(
            queue_url: dlq[:queue_url],
            attribute_names: ['QueueArn']
          )

          attrs.attributes['QueueArn']
        end

        def default_options
          {
            'DelaySeconds' => '0',
            'MaximumMessageSize' => "#{256 * 1024}",
            'VisibilityTimeout' => "#{60 * 60}", # 1 hour in seconds
            'ReceiveMessageWaitTimeSeconds' => '0',
            'MessageRetentionPeriod' => "#{7 * 24 * 60 * 60}", # 1 week in seconds
            'Policy' => policy
          }
        end

        def policy
          account_id = Shoryuken::Client.account_id
          region = sqs.config[:region]
          {
            "Version" => "2012-10-17",
            "Id" => "AnnounceSNStoSQS",
            "Statement" => [
              {
                "Sid" => "1",
                "Effect" => "Allow",
                "Principal" => {
                  "AWS" => "*"
                },
                "Action" => "sqs:*",
                "Resource" => arn,
                "Condition" => {
                  "ArnLike" => {
                    "aws:SourceArn" => "arn:aws:sns:#{region}:#{account_id}:*"
                  }
                }
              }
            ]
          }.to_json
        end

        def sqs
          Shoryuken::Client.sqs
        end
      end

      class AnnounceWorker #:nodoc:
        include Shoryuken::Worker

        attr_accessor :job_class

        shoryuken_options body_parser: :json, auto_delete: true

        def perform(sqs_msg, hash)
          job = job_class.new(hash)
          Base.execute(job.serialize)
        end
      end

      class AnnounceWorkerRegistry < Shoryuken::DefaultWorkerRegistry

        attr_accessor :subscriptions

        def initialize
          super
          @subscribers = {}
        end

        def clear
          super
          @subscribers.clear
        end

        def fetch_worker(queue, message)
          super.tap do |worker|
            if @subscribers[queue] && worker.respond_to?('job_class=')
              worker.job_class = @subscribers[queue]
            end
          end
        end

        def register_worker(queue, clazz, subscription = false)
          if subscription && active_job?
            @subscribers[queue] = clazz
            clazz = AnnounceWorker
          end
          super(queue, clazz)
        end

        def active_job?
          defined?(::ActiveJob) && ::ActiveJob::Base.queue_adapter.to_s == 'shoryuken'
        end
      end

    end
  end
end

Shoryuken.worker_registry = Announce::Adapters::ShoryukenAdapter::AnnounceWorkerRegistry.new
Shoryuken::Client.account_id = ENV['AWS_ACCOUNT_ID'] unless Shoryuken::Client.account_id
