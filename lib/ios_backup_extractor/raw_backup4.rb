module IosBackupExtractor
  class RawBackup4 < RawBackup
    MANIFEST_MBDB = 'Manifest.mbdb'

    def initialize(backup_directory)
      super(backup_directory)

      raise "This looks like a very old backup (iOS 3?)" unless @manifest_plist.has_key? 'BackupKeyBag'
      if @manifest_plist["IsEncrypted"]
        logger.info "Encrypted backup"
        @keybag = Keybag.createWithBackupManifest(@manifest_plist, 'test')
      end

      @mbdb = MBDB.new(File.join(@backup_directory, MANIFEST_MBDB))
    end

    private
    def do_extract_to(destination_directory, options)
      copy_files(destination_directory, options)
      add_files_with_extensions(destination_directory)
    end

    # Copy a file from the backup to destination
    def copy_files(destination_directory, options = {})
      destination_directory = NauktisUtils::FileBrowser.ensure_valid_directory(destination_directory)

      @mbdb.files.each do |f|
        if f[:type] == '-'
          # Check filters
          continue unless options[:domain_filter].nil? or f[:domain] =~ options[:domain_filter]
          continue unless options[:file_path_filter].nil? or f[:file_path] =~ options[:file_path_filter]
          continue unless options[:domain_except_filter].nil? or not (f[:domain] =~ options[:domain_except_filter])
          continue unless options[:file_path_except_filter].nil? or not (f[:file_path] =~ options[:file_path_except_filter])

          destination = File.expand_path(File.join(destination_directory, f[:domain], f[:file_path]))
          raise "File #{destination} already exists" if File.exists?(destination)

          source = File.expand_path(File.join(@backup_directory, f[:file_id]))
          raise "File #{source} doesn't exist in your backup source" unless File.exists?(source)

          logger.debug(self.class.name) {"Extracting #{destination}"}
          FileUtils.mkdir_p(File.dirname(destination))

          if not f[:encryption_key].nil? and not @keybag.nil?
            key = @keybag.unwrapKeyForClass(f[:protection_class], f[:encryption_key][4..-1])

            cipher = OpenSSL::Cipher::AES256.new(:CBC)
            cipher.decrypt
            cipher.key = key
            buf = ""
            File.open(destination, "wb") do |outf|
              File.open(source, "rb") do |inf|
                while inf.read(4096, buf)
                  outf << cipher.update(buf)
                end
                outf << cipher.final
              end
            end
          else
            FileUtils.cp(source, destination)
          end
        end
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
