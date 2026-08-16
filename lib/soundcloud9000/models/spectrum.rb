module Soundcloud9000
  module Models
    class Spectrum
      BAR_COUNT = 32
      MAXIMUM_VALUE = 1000.0

      attr_reader :levels

      def initialize
        @levels = Array.new(
          BAR_COUNT,
          0.0
        )

        @pid = nil
        @reader = nil
        @thread = nil

        start
      end

      def running?
        return false if @pid.nil?

        Process.kill(
          0,
          @pid
        )

        true
      rescue Errno::ESRCH
        false
      end

      def stop
        pid = @pid
        @pid = nil

        begin
          Process.kill(
            'TERM',
            pid
          ) if pid
        rescue Errno::ESRCH
          nil
        end

        @reader&.close
        @reader = nil

        begin
          Process.wait(
            pid
          ) if pid
        rescue Errno::ECHILD
          nil
        end

        @levels = Array.new(
          BAR_COUNT,
          0.0
        )
      end

      private

      def start
        config_path = File.expand_path(
          '../../../cava-soundcloud9000.conf',
          __dir__
        )

        return unless File.exist?(
          config_path
        )

        reader, writer = IO.pipe

        @pid = Process.spawn(
          'cava',
          '-p',
          config_path,
          out: writer,
          err: File::NULL
        )

        writer.close
        @reader = reader

        read_frames
      rescue Errno::ENOENT
        @pid = nil
        @levels = Array.new(
          BAR_COUNT,
          0.0
        )
      end

      def read_frames
        @thread = Thread.new do
          @reader.each_line do |line|
            values = line
              .strip
              .split(';')
              .reject(&:empty?)
              .first(BAR_COUNT)
              .map do |value|
                normalize(value)
              end

            next if values.empty?

            if values.length < BAR_COUNT
              values += Array.new(
                BAR_COUNT - values.length,
                0.0
              )
            end

            @levels = values
          end
        rescue IOError
          nil
        ensure
          @levels = Array.new(
            BAR_COUNT,
            0.0
          )
        end
      end

      def normalize(value)
        numeric = value.to_f /
                  MAXIMUM_VALUE

        [
          [numeric, 0.0].max,
          1.0
        ].min
      end
    end
  end
end

