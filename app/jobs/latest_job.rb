require "torquebox-messaging"

class LatestJob
  def initialize
    @queue = TorqueBox::Messaging::Queue.new('/queues/cache')
  end

  def run
    @queue.publish({:type => :latest, :url => nil})
  end
end
