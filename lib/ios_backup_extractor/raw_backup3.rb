module IosBackupExtractor
  class RawBackup3 < RawBackup
    private

    def load!(options = {})
      unless @loaded
        logger.debug(self.class.name) { 'Loading backup' }
        logger.info(self.class.name) { "Files in the original backup directory #{IosBackupExtractor.file_count(@backup_directory)}" }

        p @backup_directory


        if @manifest_plist['IsEncrypted'] && @manifest_plist['IsEncrypted'] != 0
          raise "Encrypted backup for iOS 3 and below are not supported."
        end

        @manifest_data = IosBackupExtractor.plist_data_to_hash(@manifest_plist['Data']) 
        @loaded = true
      end
    end

    # Copy a file from the backup to destination
    def copy_files(destination_directory, options = {})
      destination_directory = NauktisUtils::FileBrowser.ensure_valid_directory(destination_directory)

      @manifest_data['Files'].each_pair do |key, value|
        puts key
        puts value

        mdinfo_file = File.join(@backup_directory, "#{key}.mdinfo")
        mdinfo_file = File.expand_path(mdinfo_file)
        raise "File #{mdinfo_file} doesn't exist in your backup source" unless File.exists?(mdinfo_file)

        mddata_file = File.join(@backup_directory, "#{key}.mddata")
        mddata_file = File.expand_path(mddata_file)
        raise "File #{mddata_file} doesn't exist in your backup source" unless File.exists?(mddata_file)

        mdinfo = IosBackupExtractor.plist_file_to_hash(mdinfo_file)

        domain, path = mdinfo['Domain'], mdinfo['Path']
        if mdinfo['Metadata']
          mdinfo_metadata = IosBackupExtractor.plist_data_to_hash(mdinfo['Metadata'])
          domain, path = mdinfo_metadata['Domain'], mdinfo_metadata['Path']
        end

        p mdinfo
        p mdinfo_metadata

        destination = File.expand_path(File.join(destination_directory, domain, path))
        copy_file_from_backup(mddata_file, destination)
      end
    end

    def add_files_with_extensions(destination_directory)

    end
  end
end
