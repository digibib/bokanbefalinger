# -----------------------------------------------------------------------------
# torquebox.rb - torquebox settings
# -----------------------------------------------------------------------------
# Edit this file to set scheduled jobs, queues and long running processess

TorqueBox.configure do

  web do
    context "/" # where to mount application
  end


  # Message queues

  options_for :messaging, :default_message_encoding => :edn

  queue '/queues/cache' do
    processor CacheProcessor
  end


  # Scheduled jobs (cron)

  job LatestJob do
    cron "0 0/15 * * * ?"
  end

  job FeedsJob do
    cron "0 0 5 * * ?"
  end
end
