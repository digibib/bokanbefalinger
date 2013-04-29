require_relative "../../lib/refresh"

class CacheProcessor < TorqueBox::Messaging::MessageProcessor
  def on_message(body)
    case body[:type]
    when :latest
      Refresh.latest
    when :feeds
      Refresh.feeds
    when :dropdowns
      #Todo
    when :review
      Refresh.review(body[:uri])
    when :author
      Refresh.author(body[:uri])
    when :work
      Refresh.work(body[:uri])
    when :reviewer
      Refresh.reviewer(body[:uri])
    when :source
      Refresh.source(body[:uri])
    end
  end
end