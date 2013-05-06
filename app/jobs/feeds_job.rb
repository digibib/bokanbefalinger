# -----------------------------------------------------------------------------
# feeds_job.rb - job to refresh feeds cache
# -----------------------------------------------------------------------------
# Dispatches a message to the recaching queue

require "torquebox-messaging"

class FeedsJob
  def initialize
    @queue = TorqueBox::Messaging::Queue.new('/queues/cache')
  end

  def run
    @queue.publish({:type => :feeds, :url => nil})
  end
end
