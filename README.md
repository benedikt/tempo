# Tempo [![Build Status](https://travis-ci.org/benedikt/tempo.png?branch=master)](https://travis-ci.org/benedikt/tempo) [![Dependency Status](https://gemnasium.com/benedikt/tempo.png)](http://gemnasium.com/benedikt/tempo) [![Code Climate](https://codeclimate.com/github/benedikt/tempo.png)](https://codeclimate.com/github/benedikt/tempo)

Tempo is a simple templating system based on the Handlebars syntax. It provides a safe framework to render user provided templates without affecting the security of the server they are rendered on. It is designed to be easily extendable, without relying on global state.

## Requirements

* [Ruby Language Toolkit (RLTK)](http://https://github.com/chriswailes/RLTK) (~> 2.2)

## Installation

Add this line to your application's Gemfile:

    gem 'tempo'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tempo

## Usage

**Tempo is still under heavy development, so the following is mostly pseudo-code, yet.**

The simplest way to use Tempo is to use the `Tempo.render` method. Pass it a template and a context hash and it renders the template. 

```ruby
Tempo.render('This is a {{demo}}.', :demo => 'simple demo')
# => This is a simple demo.
```

In order to add custom helpers you've to create a new instance of `Tempo::Runtime` and configure it according to your needs.

```ruby
tempo = Tempo::Runtime.new do |runtime|
  runtime.partials.register(:header, '<header>{{title}}</header>')
  runtime.helpers.register(:truncate) do |input, options|
    length = options[:length]
    input[0..length]
  end
end

tempo.render('{{> header}} This is fun! {{truncate "This is a long sentence that needs to be truncated" length=20}}...', :title => 'Title here')
# => <header>Title here</header> This is fun! This is a long sente...
```


### Contexts

```ruby
class Page
  attr_accessor :title, :created_at, :user

  def to_tempo
    PageContext.new(self)
  end
end

class PageContext < Tempo::Context
  allows :title, :created_at
end

page = Page.new
page.title = 'Example'
page.created_at = Time.now
page.user = 'Benedikt'

Tempo.render('The page "{{title}}" was created at {{created_at}}', page)
# => The page "Example" was created at 2013-10-07 17:13:40 +0000

Tempo.render('The page "{{title}}" was created by "{{user}}"', page)
# => The page "Example" was created by ""
```


### Helpers

```ruby
tempo = Tempo::Runtime.new do |runtime|
  runtime.helpers.register(:random_block) do
    rand <= 0.5 ? yield : ''
  end
end

tempo.render('{{#random_block}}This is visible in 50% of the cases{{/random_block}}')
# => This is visible in 50% of the cases
```

```ruby
class FancyHelper < Tempo::Helper
  def call(arg1, arg2, options)
    if arg1 == arg2
      contents
    else
      inverse
    end
  end
end

tempo = Tempo::Runtime.new do |runtime|
  runtime.helpers.register(:fancy, FancyHelper.new)
end

rempo.render('{{#fancy 1 2}}The arguments are equal{{else}}The arguments are not equal{{/fancy}}')
# => The arguments are not equal
```


### Partials

It's possible to customize the way Tempo looks up the partials. By default it uses the `Tempo::PartialContext` which requires you to manually register each partial.
Tempo provides a `Tempo::FilePartialContext` which looks up the templates in the given directory on the file system. 

```ruby
tempo = Tempo::Runtime.new do |runtime|
  runtime.partials = Tempo::FilePartialContext.new('/path/to/templates')
end
```

To further customize this, you can provide your own PartialContext. The following example looks up the partials in the database.

```ruby
class CustomPartialContext
  def lookup(partial)
    template = Template.find_by_name(partial)
    template ? template.content : "Partial #{partial} could not be found!"
  end
end

tempo = Tempo::Runtime.new do |runtime|
  runtime.partials = CustomPartialContext.new
end
```


## Build Status

tempo is on [Travis CI](https://travis-ci.org/benedikt/tempo) running the specs on Ruby 1.9, Ruby 2.0, JRuby (1.9 mode), and Rubinius 2.0.

## Known issues

See [the issue tracker on GitHub](https://github.com/benedikt/tempo/issues) for a list of known issues.

## Repository

The repository is [available on GitHub](https://github.com/benedikt/tempo). Feel free to fork it!

## Contributors and special thanks

See a [list of all contributors on GitHub](https://github.com/benedikt/tempo/contributors). Thanks a lot to everyone!

Special thanks go to:

* Kevin Garnett: For suggesting the name "Tempo"
* Gregory T. Brown: For giving away the name on RubyGems

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2013 Benedikt Deicke. See LICENSE for details.