# encoding: UTF-8

# -----------------------------------------------------------------------------
# models/init.rb - application globals + load all models
# -----------------------------------------------------------------------------

# Globals:
QUEUE = TorqueBox::Messaging::Queue.new('/queues/cache')

Dropdown = Struct.new(:subjects, :persons, :genres, :languages, :authors,
                      :formats, :nationalities)

require_relative "../lib/sparql"

# load all models
require_relative "review"
require_relative "review2"
require_relative "list2"
require_relative "work2"
require_relative "work"
require_relative "user"