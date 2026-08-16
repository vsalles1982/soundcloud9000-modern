$LOAD_PATH.push(
  File.expand_path(
    'lib',
    __dir__
  )
)

Gem::Specification.new do |spec|
  spec.name = 'soundcloud9000'
  spec.version = '0.2.0'

  spec.authors = [
    'Tobias Schmidt',
    'Matthias Georgi',
    'Sumanth Ratna',
    'vsalles82'
  ]

  spec.summary =
    'Modern SoundCloud terminal client'

  spec.description =
    'Ruby and curses SoundCloud terminal player ' \
    'with API v2, mpv and Cava support'

  spec.homepage =
    'https://github.com/sumanthratna/soundcloud9000'

  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.1'

  spec.bindir = 'bin'
  spec.executables = ['soundcloud9000']
  spec.require_paths = ['lib']

  spec.files = Dir.glob(
    [
      'bin/**/*',
      'lib/**/*',
      'README.md',
      'README-MODERN.md',
      'LICENSE',
      'cava-soundcloud9000.conf'
    ]
  )

  spec.requirements << 'mpv'
  spec.requirements << 'cava'

  spec.add_dependency(
    'curses',
    '>= 1.4',
    '< 2'
  )

  spec.add_dependency(
    'logger',
    '>= 1.6',
    '< 2'
  )

  spec.add_development_dependency(
    'bundler',
    '>= 2.7',
    '< 5'
  )

  spec.add_development_dependency(
    'rake',
    '~> 13.0'
  )

  spec.add_development_dependency(
    'minitest',
    '~> 5.25'
  )

  spec.add_development_dependency(
    'mocha',
    '~> 2.0'
  )
end
