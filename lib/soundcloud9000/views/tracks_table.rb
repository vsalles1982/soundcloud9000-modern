require_relative '../ui/table'

module Soundcloud9000
  module Views
    class TracksTable < UI::Table
      COLUMN_WEIGHTS = [
        0.52,
        0.23,
        0.10,
        0.075,
        0.075
      ].freeze

      def initialize(*args)
        super

        self.header = [
          'Title',
          'User',
          'Length',
          'Likes',
          'Comments'
        ]

        self.keys = [
          :title,
          :username,
          :length,
          :likes,
          :comments
        ]
      end

      protected

      def perform_layout
        separator_width =
          (
            header.length - 1
          ) * SEPARATOR.length

        available_width = [
          rect.width - separator_width,
          header.length
        ].max

        @sizes = COLUMN_WEIGHTS.map do |weight|
          [
            (
              available_width *
              weight
            ).floor,
            1
          ].max
        end

        difference =
          available_width -
          @sizes.sum

        @sizes[0] += difference
      end

      def body_height
        [
          rect.height - 1,
          1
        ].max
      end
    end
  end
end
