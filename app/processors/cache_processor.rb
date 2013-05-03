#encoding: UTF-8

require "torquebox-messaging"
require_relative "../../lib/refresh"

class CacheProcessor < TorqueBox::Messaging::MessageProcessor

  @@queue = TorqueBox::Messaging::Queue.new('/queues/cache')

  def on_message(body)
    case body[:type]
    when :review_include_affected
      rev = Refresh.review(body[:uri])

      # enqueue other uris affected by the review
      @@queue.publish({:type => :work, :uri => rev["works"].first["uri"]})
      @@queue.publish({:type => :reviewer, :uri => rev["works"].first["reviews"].first["reviewer"]["uri"]})
      rev["works"].first["authors"].each do |author|
        @@queue.publish({:type => :author, :uri => author["uri"]})
      end
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