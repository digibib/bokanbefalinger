TorqueBox.configure do
  web do
    context "/"
  end

  options_for :messaging, :default_message_encoding => :edn

  # Message queues
  queue '/queues/cache' do
    processor CacheProcessor
  end

  # Scheduled jobs (cron)
  job LatestJob do
    cron "0 0/15 * * * ?"
  end
end
