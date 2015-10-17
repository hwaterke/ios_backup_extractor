module IosBackupExtractor
  class RawBackup4 < RawBackup
    MANIFEST_MBDB = 'Manifest.mbdb'

    def initialize(backup_directory)
      super.initialize(backup_directory)
      puts @manifest_plist["IsEncrypted"]? "Backup is encrypted." : "Backup is not encrypted."
      raise "This looks like a very old backup (iOS 3?)" unless @manifest_plist.has_key? 'BackupKeyBag'
      mbdb = MBDB.new(File.join(@backup_directory, MANIFEST_MBDB))
    end
  end
end