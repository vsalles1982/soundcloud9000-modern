require_relative 'soundcloud9000/client'
require_relative 'soundcloud9000/application'
require_relative 'soundcloud9000/doctor'
require_relative 'soundcloud9000/models/user'

module Soundcloud9000
  def self.start
    if ARGV.include?('--doctor')
      exit(Doctor.run(ENV['SC_CLIENT_ID']) ? 0 : 1)
    end

    client_id = ENV['SC_CLIENT_ID']

    unless client_id
      puts 'You need to set SC_CLIENT_ID to a valid client ID'
      exit 1
    end

    unless ARGV.empty?
      if ARGV.include?('-v') || ARGV.include?('--version')
        puts Application.get_version
        exit 0
      elsif ARGV.include?('-h') || ARGV.include?('--help')
        puts Application.get_help
        exit 0
      else
        puts "Unknown option: #{ARGV[0]}"
        exit 1
      end
    end

    client = Client.new(client_id)

    username = ENV['SC_USERNAME']

    unless username.to_s.empty?
      user_hash = client.resolve(username)

      if user_hash
        client.current_user = Models::User.new(user_hash)
      else
        warn "Could not resolve SoundCloud user '#{username}'."
      end
    end

    application = Application.new(client)

    Signal.trap('SIGINT') do
      application.stop
    end

    application.run
  end
end
