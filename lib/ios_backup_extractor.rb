require 'digest/sha1'
require 'fileutils'

require 'active_support'
require 'active_support/core_ext/numeric'
require 'aes_key_wrap'
require 'cfpropertylist'
require 'nauktis_utils'
require 'sqlite3'

require 'ios_backup_extractor/version'
require 'ios_backup_extractor/info_plist'
require 'ios_backup_extractor/mbdb'
require 'ios_backup_extractor/keybag'
require 'ios_backup_extractor/raw_backup'
require 'ios_backup_extractor/raw_backup3'
require 'ios_backup_extractor/raw_backup4'
require 'ios_backup_extractor/raw_backup10'
require 'ios_backup_extractor/backup_retriever'

module IosBackupExtractor

  ##
  # Returns the number of files contained in +directory+

  def self.file_count(directory)
    count = 0
    Find.find(File.expand_path(directory)) do |path|
      count += 1 unless FileTest.directory?(path)
    end
    count
  end

  # TODO Move helpers somewhere else.
  def self.plist_data_to_hash(data)
    CFPropertyList.native_types(CFPropertyList::List.new(data: data).value)
  end

  def self.plist_file_to_hash(file)
    file = NauktisUtils::FileBrowser.ensure_valid_file(file)
    CFPropertyList.native_types(CFPropertyList::List.new(:file => file).value)
  end
end
