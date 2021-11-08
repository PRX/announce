require "shoryuken"
require "announce/adapters/base_adapter"

module Announce
  module Adapters
    class ShoryukenAdapter < BaseAdapter
      class AnnounceWorker #:nodoc:
        include Shoryuken::Worker

        shoryuken_options body_parser: :json, auto_delete: true

        # overriden in register_class
        def job_class; end

        def perform(sqs_msg, hash)
          job = job_class.new(hash)
          ActiveJob::Base.execute(job.serialize)
        end
      end

      class Subscriber < BaseAdapter::Subscriber
        def subscribe(worker_class, subject, actions, options)
          Array(actions).each do |action|
            queue_name = Queue.name_for(subject, action)
            Shoryuken.register_worker(queue_name, register_class(worker_class))
            Shoryuken.queues << queue_name
          end
        end

        def register_class(worker_class)
          if active_job?
            Class.new(AnnounceWorker).tap do |jc|
              jc.class_eval("def job_class; #{worker_class.name}; end")
            end
          else
            worker_class
          end
        end

        def active_job?
          defined?(::ActiveJob) &&
            defined?(ActiveJob::QueueAdapters::ShoryukenAdapter) &&
            ActiveJob::Base.queue_adapter ==
              ActiveJob::QueueAdapters::ShoryukenAdapter
        end
      end

      class BrokerManager < BaseAdapter::BrokerManager
        # actually configure the broker queues, topics, and subscriptions
        def configure
          if options[:verify_only]
            Announce.logger.warn(
              "Running Announce BrokerManager configure in verify_only mode."
            )
            Announce.logger.warn(
              "Resources will be logged, not created; please verify they exist."
            )
          end
          configure_publishing && configure_subscribing
        end

        def configure_publishing
          (options[:publish] || {}).each do |subject, actions|
            Array(actions).each do |action|
              topic = ShoryukenAdapter::Topic.new(subject, action, options)
              options[:verify_only] ? topic.verify : topic.create
            end
          end
          true
        end

        def configure_subscribing
          (options[:subscribe] || {}).each do |subject, actions|
            Array(actions).each do |action|
              topic = ShoryukenAdapter::Topic.new(subject, action, options)
              queue = ShoryukenAdapter::Queue.new(subject, action, options)
              if options[:verify_only]
                topic.verify
                queue.verify
                topic.verify_subscription(queue)
              else
                topic.create
                queue.create
                topic.subscribe(queue)
              end
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

        def verify
          Announce.logger.warn("Verify SNS Topic: #{arn}")
        end

        def verify_subscription(queue)
          Announce.logger.warn(
            "Verify Subscription:\n" + "\tfrom SNS Topic: #{arn}\n" +
              "\tto SQS Queue: #{queue.arn}"
          )
        end

        def subscribe(queue)
          subscription_arn =
            sns.subscribe(topic_arn: arn, protocol: "sqs", endpoint: queue.arn)[
              :subscription_arn
            ]

          sns.set_subscription_attributes(
            subscription_arn: subscription_arn,
            attribute_name: "RawMessageDelivery",
            attribute_value: "true"
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
        DLQ_SUFFIX = "failures".freeze

        def create
          dlq_arn = create_dlq

          create_attributes =
            default_options.merge((options[:queues] || {}).stringify_keys)
          create_attributes["RedrivePolicy"] =
            "{\"maxReceiveCount\":\"10\", \"deadLetterTargetArn\":\"#{
              dlq_arn
            }\"}\""

          sqs.create_queue(queue_name: name, attributes: create_attributes)[
            :queue_url
          ]
        end

        def verify
          Announce.logger.warn(
            "Verify SQS Queue: #{arn}\n\t with DLQ: #{dlq_arn}"
          )
        end

        def arn
          account_id = Shoryuken::Client.account_id
          region = sqs.config[:region]
          "arn:aws:sqs:#{region}:#{account_id}:#{name}"
        end

        def create_dlq
          dlq_options = {
            "MaximumMessageSize" => "#{(256 * 1024)}",
            "MessageRetentionPeriod" => "#{2 * 7 * 24 * 60 * 60}"
            # 2 weeks in seconds
          }

          dlq = sqs.create_queue(queue_name: dlq_name, attributes: dlq_options)

          attrs =
            sqs.get_queue_attributes(
              queue_url: dlq[:queue_url], attribute_names: %w[QueueArn]
            )

          attrs.attributes["QueueArn"]
        end

        def dlq_arn
          [arn, DLQ_SUFFIX].join(self.class.delimiter)
        end

        def dlq_name
          [name, DLQ_SUFFIX].join(self.class.delimiter)
        end

        def default_options
          {
            "DelaySeconds" => "0",
            "MaximumMessageSize" => "#{256 * 1024}",
            "VisibilityTimeout" => "#{60 * 60}",
            # 1 hour in seconds
            "ReceiveMessageWaitTimeSeconds" => "0",
            "MessageRetentionPeriod" => "#{7 * 24 * 60 * 60}",
            # 1 week in seconds
            "Policy" => policy
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
                "Principal" => { "AWS" => "*" },
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
    end
  end
end

unless Shoryuken::Client.account_id
  Shoryuken::Client.account_id = ENV["AWS_ACCOUNT_ID"]
end
