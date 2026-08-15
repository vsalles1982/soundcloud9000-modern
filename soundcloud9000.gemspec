$LOAD_PATH.push File.expand_path('lib', __dir__)

Gem::Specification.new do |spec|
  spec.name = 'soundcloud9000'
  spec.version = '0.2.0.pre1'

  spec.authors = [
    'Tobias Schmidt',
    'Matthias Georgi',
    'Sumanth Ratna'
  ]

  spec.summary = 'SoundCloud terminal client'
  spec.description = 'Modernized Ruby and curses SoundCloud terminal player'
  spec.homepage = 'https://github.com/sumanthratna/soundcloud9000'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.1'

  spec.bindir = 'bin'

  spec.files = Dir.glob(
    [
      'bin/**/*',
      'lib/**/*',
      'README.md',
      'README-MODERN.md',
      'LICENSE'
    ]
  )

  spec.executables = ['soundcloud9000']
  spec.require_paths = ['lib']

  spec.requirements << 'mpv'

  spec.add_dependency 'curses', '>= 1.4', '< 2'
  spec.add_dependency 'logger', '>= 1.6', '< 2'

  spec.add_development_dependency 'bundler', '>= 2.7', '< 5'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'mocha', '~> 2.0'
end
