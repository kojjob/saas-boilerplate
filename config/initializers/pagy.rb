# frozen_string_literal: true

# Pagy initializer for Pagy ~> 9.x
# See https://ddnexus.github.io/pagy/docs/how-to/

require 'pagy/extras/overflow'

# Default number of items per page
Pagy::DEFAULT[:limit] = 25

# Default size for the pagination nav bar
Pagy::DEFAULT[:size] = 7

# Overflow handling
Pagy::DEFAULT[:overflow] = :last_page
