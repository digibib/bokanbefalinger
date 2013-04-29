require "torquebox-messaging"

class FeedsJob
  def initialize
    @queue = TorqueBox::Messaging::Queue.new('/queues/cache')
  end

  def run
    @queue.publish({:type => :feeds, :url => nil})
  end
end
