module IosBackupExtractor
  class RawBackup4 < RawBackup
    MANIFEST_MBDB = 'Manifest.db'

    def initialize(backup_directory)
      super(backup_directory)

      raise "This looks like a very old backup (iOS 3?)" unless @manifest_plist.has_key? 'BackupKeyBag'
      if @manifest_plist["IsEncrypted"]
        logger.info "Encrypted backup"
        @keybag = Keybag.createWithBackupManifest(@manifest_plist, 'test')
      end

      @manifest = SQLite3::Database.new(File.join(@backup_directory, MANIFEST_DB))
    end

    private
    def do_extract_to(destination_directory, options)
      copy_files(destination_directory, options)
      add_files_with_extensions(destination_directory)
    end

    # Copy a file from the backup to destination
    def copy_files(destination_directory, options = {})
      destination_directory = NauktisUtils::FileBrowser.ensure_valid_directory(destination_directory)

      @manifest.execute("SELECT * FROM Files") do |row|
        p row
      end
    end

    # Adds all files that have an extension
    def add_files_with_extensions(destination_directory)
      Dir.entries(@backup_directory).each do |entry|
        path = File.expand_path(File.join(@backup_directory, entry))
        unless FileTest.directory?(path)
          unless File.extname(path).empty?
            logger.info(self.class.name) {"Keeping #{File.basename(path)} in the backup."}
            FileUtils.cp(NauktisUtils::FileBrowser.ensure_valid_file(path), destination_directory)
          end
        end
      end
      raise "Info.plist was not added" unless File.exists?(File.join(destination_directory, INFO_PLIST))
    end
  end
end
