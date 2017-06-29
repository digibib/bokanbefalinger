# encoding: UTF-8

# -----------------------------------------------------------------------------
# models/init.rb - application globals + load all models
# -----------------------------------------------------------------------------

# Globals:

SearchDropdown = Struct.new(:authors, :titles, :reviewers, :sources)
Dropdown = Struct.new(:subjects, :persons, :genres, :languages, :authors,
                      :formats, :nationalities)

require_relative "../lib/sparql"

# load all models
require_relative "review"
require_relative "list"
require_relative "work"
require_relative "user"