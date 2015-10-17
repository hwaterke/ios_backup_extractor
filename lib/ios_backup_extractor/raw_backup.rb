module IosBackupExtractor
  class RawBackup
    INFO_PLIST = 'Info.plist'
    MANIFEST_PLIST = 'Manifest.plist'
    MANIFEST_MBDB = 'Manifest.mbdb'

    def initialize(backup_directory)
      @backup_directory = NauktisUtils::FileBrowser.ensure_valid_directory(backup_directory)
      
      @manifest_plist = IosBackupExtractor.plist_to_hash(File.join(@backup_directory, MANIFEST_PLIST))
      @info_plist = IosBackupExtractor.plist_to_hash(File.join(@backup_directory, INFO_PLIST))
      
      print_info
      puts @manifest_plist["IsEncrypted"]? "Backup is encrypted." : "Backup is not encrypted."

      raise "This looks like a very old backup (iOS 3?)" unless @manifest_plist.has_key? 'BackupKeyBag'

      mbdb = MBDB.new(File.join(@backup_directory, MANIFEST_MBDB))
    end

    def print_info
      ["Device Name", "Display Name", "Last Backup Date", "IMEI", "Serial Number", "Product Type", "Product Version", "iTunes Version"].each do |i|
        puts "#{i}: #{@info_plist[i]}"
      end
    end
  end
end
