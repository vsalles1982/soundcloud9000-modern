require 'open3'

module Soundcloud9000
  class Doctor
    def self.run(client_id = nil)
      checks = {
        'Ruby 3.1+' => RUBY_VERSION.split('.').first(2).join('.').to_f >= 3.1,
        'curses gem' => dependency?('curses'),
        'mpv executable' => executable?('mpv'),
        'SC_CLIENT_ID' => !client_id.to_s.empty?
      }

      checks.each { |name, valid| puts "#{valid ? 'OK' : 'FAIL'}  #{name}" }
      checks.values.all?
    end

    def self.dependency?(name)
      require name
      true
    rescue LoadError
      false
    end

    def self.executable?(name)
      _output, status = Open3.capture2e('sh', '-c', 'command -v "$1"', 'doctor', name)
      status.success?
    end
  end
end
