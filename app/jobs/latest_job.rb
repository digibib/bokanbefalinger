# -----------------------------------------------------------------------------
# latest_job.rb - job to refresh cache and fetch latest reviews + dropdowns
# -----------------------------------------------------------------------------
# Dispatches a message to the recaching queue

require "torquebox-messaging"

class LatestJob
  def initialize
    @queue = TorqueBox::Messaging::Queue.new('/queues/cache')
  end

  def run
    @queue.publish({:type => :latest, :url => nil})

    # also refresh dropdowns cache
    @queue.publish({:type => :dropdowns, :url => nil})
  end
end
