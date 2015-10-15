module IosBackupExtractor
  class RawBackup
    def initialize(backup_directory)
      @backup_directory = NauktisUtils::FileBrowser.ensure_valid_directory(backup_directory)
      manifest_plist = CFPropertyList.native_types((CFPropertyList::List.new(:file => File.join(@backup_directory, 'Manifest.plist')).value)
      p info_plist = CFPropertyList.native_types(CFPropertyList::List.new(:file => File.join(@backup_directory, 'Info.plist')).value)
      # TODO parse the MBDB
    end
  end
end
