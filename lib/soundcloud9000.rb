require_relative 'soundcloud9000/client'
require_relative 'soundcloud9000/application'
require_relative 'soundcloud9000/doctor'

module Soundcloud9000
  def self.start
    if ARGV.include?('--doctor')
      exit(Doctor.run(ENV['SC_CLIENT_ID']) ? 0 : 1)
    end

    unless client_id = ENV['SC_CLIENT_ID']
      puts 'You need to set SC_CLIENT_ID to a valid client ID'
      exit 1
    end

    if !ARGV.empty?
      if ARGV.include?('-v') || ARGV.include?('--version')
        puts Application.get_version
        puts "Copyright (C) #{Time.new.year} Sumanth Ratna"
        exit 0
      elseif ARGV.include?('-h') || ARGV.include?('--help')
        puts Application.get_help
        exit 0
      else
        puts "Unknown option: #{ARGV[0]}"
        exit 1
      end
    end

    client = Client.new(client_id)
    application = Application.new(client)

    Signal.trap('SIGINT') do
      application.stop
    end

    application.run
  end
end
