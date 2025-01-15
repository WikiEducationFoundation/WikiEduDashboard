# frozen_string_literal: true

module Errors
  module PageContentErrors
    class NilPageContentError < StandardError
      def initialize(page)
        msg = "Failed to fetch content for #{page}. Initial page content is nil."
        super(msg)
      end
    end
  end
end
