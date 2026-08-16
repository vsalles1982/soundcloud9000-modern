require 'curses'

require_relative 'color'

module Soundcloud9000
  module UI
    class View
      ROW_SEPARATOR = '|'.freeze
      LINE_SEPARATOR = '-'.freeze
      INTERSECTION = '+'.freeze

      attr_reader :rect

      def initialize(rect)
        @rect = rect

        @window = Curses::Window.new(
          rect.height,
          rect.width,
          rect.y,
          rect.x
        )

        @line = 0
        @padding = 0
      end

      def padding(value = nil)
        if value.nil?
          @padding
        else
          @padding = value
        end
      end

      def render
        @window.erase

        perform_layout
        reset
        draw
        refresh
      end

      def body_width
        [
          rect.width - 2 * padding,
          1
        ].max
      end

      def with_color(name, &block)
        @window.attron(
          Color.get(name),
          &block
        )
      end

      def clear
        @window.erase
      end

      protected

      def lines_left
        rect.height - @line - 1
      end

      def line(content)
        return if @line >= rect.height

        @window.setpos(
          @line,
          padding
        )

        visible_content = content
          .to_s
          .ljust(body_width)
          .slice(0, body_width)

        @window.addstr(
          visible_content
        )

        @line += 1
      end

      def reset
        @line = 0
      end

      def refresh
        @window.refresh
      end

      def perform_layout
        nil
      end

      def draw
        raise NotImplementedError
      end
    end
  end
end
