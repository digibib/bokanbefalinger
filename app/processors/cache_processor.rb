# encoding: UTF-8

# -----------------------------------------------------------------------------
# cache_processor.rb - process the recaching queue
# -----------------------------------------------------------------------------
# Fetches messages one by one from the queue /queues/cache, and refreshes the
# cache on the uri(s) given in the message.

require "torquebox-messaging"
require_relative "../../lib/refresh"

class CacheProcessor < TorqueBox::Messaging::MessageProcessor

  @@queue = TorqueBox::Messaging::Queue.new('/queues/cache')

  def on_message(body)
    # Processes messages in the format {:type => <type> :uri => <uri/nil> }

    case body[:type]
    when :review_include_affected
      rev = Refresh.review(body[:uri])

      # enqueue other uris affected by the review:

      # 1. work:
      @@queue.publish({:type => :work, :uri => rev["works"].first["uri"]})
      # 2. reviewer:
      @@queue.publish({:type => :reviewer,
        :uri => rev["works"].first["reviews"].first["reviewer"]["uri"]})
      # 3. author(s):
      rev["works"].first["authors"].each do |author|
        @@queue.publish({:type => :author, :uri => author["uri"]})
      end
      # 4. source:
      @@queue.publish({:type => :source, :uri => rev["works"].first["reviews"].first["source"]["uri"]})
    when :review
      _ = Refresh.review(body[:uri])
    when :author
      Refresh.author(body[:uri])
    when :work
      Refresh.work(body[:uri])
    when :reviewer
      Refresh.reviewer(body[:uri])
    when :source
      Refresh.source(body[:uri])
    when :latest
      Refresh.latest
    when :feeds
      Refresh.feeds
    when :dropdowns
      #Todo
    end
  end
end