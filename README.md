# IosBackupExtractor

Ruby script to extract iOS backups.

## Installation

    $ gem install ios_backup_extractor

## Usage

To see the list of backups on your machine run

    $ ios -l

Or if you want a detailed view

    $ ios -d
    
Extract backups to your desktop

    $ ios --extract ~/Desktop --password mypassword

If you prefer to create an archive of it

    $ ios --archive ~/Desktop --password mypassword

For more options, please refer to

    $ ios -h

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Credits and links
* https://github.com/horrorho/InflatableDonkey/issues/41
* https://github.com/dunhamsteve/ios
* https://github.com/hackappcom/iloot
* https://stackoverflow.com/questions/1498342/how-to-decrypt-an-encrypted-apple-itunes-iphone-backup
