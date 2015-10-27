require 'digest/sha1'
require 'fileutils'

require 'active_support'
require 'active_support/core_ext/numeric'
require 'aes_key_wrap'
require 'cfpropertylist'
require "nauktis_utils"

require "ios_backup_extractor/version"
require "ios_backup_extractor/mbdb"
require "ios_backup_extractor/keybag"
require "ios_backup_extractor/raw_backup"
require "ios_backup_extractor/raw_backup4"
require "ios_backup_extractor/backup_retriever"

module IosBackupExtractor
  def self.plist_to_hash(file)
    file = NauktisUtils::FileBrowser.ensure_valid_file(file)
    CFPropertyList.native_types(CFPropertyList::List.new(:file => file).value)
  end
end
