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
          raise "File #{destination} already exists" if File.exists?(destination)

          source = File.expand_path(File.join(@backup_directory, f[:file_id]))
          raise "File #{source} doesn't exist in your backup source" unless File.exists?(source)

          logger.debug(self.class.name) { "Extracting #{destination}" }
          FileUtils.mkdir_p(File.dirname(destination))

          if not f[:encryption_key].nil? and not @keybag.nil?
            key = @keybag.unwrap_key_for_class(f[:protection_class], f[:encryption_key][4..-1])

            cipher = OpenSSL::Cipher::AES256.new(:CBC)
            cipher.decrypt
            cipher.key = key
            buf = ''
            File.open(destination, 'wb') do |outf|
              File.open(source, 'rb') do |inf|
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
  end
end
