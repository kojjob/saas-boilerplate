# frozen_string_literal: true

# Pagy initializer for Pagy ~> 9.x
# See https://ddnexus.github.io/pagy/docs/api/pagy/

require 'pagy/extras/overflow'

# Default number of items per page
Pagy::DEFAULT[:limit] = 25

# Number of page links to show
Pagy::DEFAULT[:size] = 7

# Overflow handling - go to last page instead of error
Pagy::DEFAULT[:overflow] = :last_page
