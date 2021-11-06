module IosBackupExtractor
  class RawBackup4 < RawBackup
    MANIFEST_MBDB = 'Manifest.mbdb'

    private

    def load!(options = {})
      super(options)
      @mbdb = MBDB.new(File.join(@backup_directory, MANIFEST_MBDB))
    end

    # Copy a file from the backup to destination
    def copy_files(destination_directory, options = {})
      destination_directory = NauktisUtils::FileBrowser.ensure_valid_directory(destination_directory)

      @mbdb.files.each do |f|
        if f[:type] == '-'
          # Check filters
          continue unless should_include?(f[:domain], f[:file_path], options)

          destination = File.expand_path(File.join(destination_directory, f[:domain], f[:file_path]))

          if not f[:encryption_key].nil? and not @keybag.nil?
            key = @keybag.unwrap_key_for_class(f[:protection_class], f[:encryption_key][4..-1])
            copy_enc_file_from_backup(f[:file_id], destination, key)
          else
            copy_file_from_backup(f[:file_id], destination)
          end
        end
      end
    end
  end
end
