require 'fileutils'
require "nauktis_utils"
require 'cfpropertylist'
require "ios_backup_extractor/version"
require "ios_backup_extractor/mbdb"
require "ios_backup_extractor/raw_backup"

module IosBackupExtractor
  def self.plist_to_hash(file)
    file = NauktisUtils::FileBrowser.ensure_valid_file(file)
    CFPropertyList.native_types(CFPropertyList::List.new(:file => file).value)
  end
end
