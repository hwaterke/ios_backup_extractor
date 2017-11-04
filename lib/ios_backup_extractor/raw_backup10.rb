module IosBackupExtractor
  class RawBackup10 < RawBackup
    MANIFEST_DB = 'Manifest.db'

    private

    def load!(options = {})
      super(options)

      # Grab a copy of the Manifest database
      manifest_dir = Dir.mktmpdir
      major, minor = info_plist.versions
      if is_encrypted? && (major > 10 || (major == 10 && minor >= 2))
        protection_class = @manifest_plist['ManifestKey'][0..3].unpack('V')[0]
        key = @keybag.unwrap_key_for_class(protection_class, @manifest_plist['ManifestKey'][4..-1])
        copy_enc_file_from_backup(MANIFEST_DB, File.join(manifest_dir, MANIFEST_DB), key)
      else
        copy_file_from_backup(MANIFEST_DB, File.join(manifest_dir, MANIFEST_DB))
      end

      @manifest = SQLite3::Database.new(File.join(manifest_dir, MANIFEST_DB))
    end

    # Copy a file from the backup to destination
    def copy_files(destination_directory, options = {})
      destination_directory = NauktisUtils::FileBrowser.ensure_valid_directory(destination_directory)

      logger.info(self.class.name) do
        count = @manifest.execute('SELECT COUNT(fileID) FROM Files WHERE flags == 1')
        "Files in the Manifest: #{count[0][0]}"
      end

      @manifest.execute('SELECT * FROM Files') do |row|
        f = {
            file_id: row[0],
            domain: row[1],
            file_path: row[2]
        }
        flag = row[3]

        # Check filters
        next unless should_include?(f[:domain], f[:file_path], options)

        backup_file = File.expand_path(File.join(@backup_directory, f[:file_id][0..1], f[:file_id]))

        # Folders
        if flag == 2
          if File.exists?(backup_file)
            raise "Directories should not exist in the original backup... #{f[:file_id]}"
          else
            next
          end
        end

        # Symlink
        if flag == 4
          if File.exists?(backup_file)
            raise "Symlinks should not exist in the original backup... #{f[:file_id]}"
          else
            next
          end
        end

        if flag == 16
          if File.exists?(backup_file)
            raise "Flag 16 should not exist in the original backup... #{f[:file_id]}"
          else
            next
          end
        end

        destination = File.expand_path(File.join(destination_directory, f[:domain], f[:file_path]))
        data = CFPropertyList.native_types(CFPropertyList::List.new(data: row[4]).value)

        file_properties = data['$objects'][1]
        if not file_properties['EncryptionKey'].nil? and not @keybag.nil?
          key = @keybag.unwrap_key_for_class(file_properties['ProtectionClass'], data['$objects'][file_properties['EncryptionKey']]['NS.data'][4..-1])
          copy_enc_file_from_backup(backup_file, destination, key)
        else
          copy_file_from_backup(backup_file, destination)
        end
      end
    end
  end
end
