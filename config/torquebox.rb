TorqueBox.configure do
  web do
    context "/"
  end

  # re-caching queues
  queue '/queues/reviews'
  queue '/queues/works'
  queue '/queues/authors'
  queue '/queues/reviewers'

end
