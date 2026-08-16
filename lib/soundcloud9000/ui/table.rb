require_relative 'view'

module Soundcloud9000
  module UI
    class Table < View
      SEPARATOR = '  |  '.freeze

      attr_reader :current, :collection
      attr_accessor :header, :keys

      def initialize(*args)
        super

        @sizes = []
        @rows = []
        @current = 0
        @top = 0
        @selected = nil

        reset
      end

      def bind_to(collection)
        raise ArgumentError if @collection

        @collection = collection

        @collection.events.on(:append) do
          render
        end

        @collection.events.on(:replace) do
          @current = 0
          @top = 0
          @selected = nil
          clear
          render
        end
      end

      def length
        @collection.size
      end

      def body_height
        rect.height - @header.size
      end

      def bottom?
        current + 1 >= length
      end

      def up
        return unless @current.positive?

        @current -= 1
        ensure_current_visible
        render
      end

      def down
        return unless @current + 1 < length

        @current += 1
        ensure_current_visible
        render
      end

      def random
        return if length <= 1

        previous = @current
        candidate = rand(length - 1)

        candidate += 1 if candidate >= previous

        @current = candidate

        ensure_current_visible
        render
      end

      def select
        @selected = @current
        ensure_current_visible
        render
      end

      def deselect
        @selected = nil
        render
      end

      protected

      def rows(start = 0, size = collection.size)
        collection[start, size].map do |record|
          keys.map do |key|
            record.send(key).to_s
          end
        end
      end

      def rest_width(elements)
        used_width = elements.sum

        rect.width -
          elements.size * SEPARATOR.size -
          used_width
      end

      def perform_layout
        @sizes = []

        (rows + [header]).each do |row|
          row.each_with_index do |value, index|
            current_size = value.to_s.length
            maximum = @sizes[index] || 0

            if current_size > maximum
              @sizes[index] = current_size
            end
          end
        end

        @sizes[-1] = [
          rest_width(@sizes[0...-1]),
          1
        ].max
      end

      def draw
        draw_header
        draw_body
      end

      def draw_header
        with_color(:green_reverse) do
          draw_values(header)
        end
      end

      def color_for(index)
        absolute_index = @top + index

        if absolute_index == @current
          :cyan
        elsif absolute_index == @selected
          :black
        else
          :white
        end
      end

      def draw_body
        visible_rows =
          rows(@top, body_height + 1)

        visible_rows.each_with_index do |row, index|
          with_color(color_for(index)) do
            draw_values(row)
          end
        end
      end

      def draw_values(values)
        position = -1

        content = values.map do |value|
          position += 1

          value.to_s.ljust(
            @sizes[position]
          )
        end.join(SEPARATOR)

        line(content)
      end

      def ensure_current_visible
        visible_height = [
          body_height,
          1
        ].max

        if @current < @top
          @top = @current
        elsif @current >= @top + visible_height
          @top = @current - visible_height + 1
        end

        maximum_top = [
          length - visible_height,
          0
        ].max

        @top = [
          [@top, 0].max,
          maximum_top
        ].min
      end
    end
  end
end
