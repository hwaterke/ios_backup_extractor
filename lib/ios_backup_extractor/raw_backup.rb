module IosBackupExtractor
  class RawBackup
    include NauktisUtils::Logging
    attr_reader :info_plist
    INFO_PLIST = 'Info.plist'
    MANIFEST_PLIST = 'Manifest.plist'

    def initialize(backup_directory)
      @backup_directory = NauktisUtils::FileBrowser.ensure_valid_directory(backup_directory)
      @info_plist = InfoPlist.new(File.join(@backup_directory, INFO_PLIST))
      @manifest_plist = IosBackupExtractor.plist_file_to_hash(File.join(@backup_directory, MANIFEST_PLIST))
      raise 'This looks like a very old backup (iOS 3?)' unless @manifest_plist.has_key? 'BackupKeyBag'
    end

    ##
    # Creates a tar archive of the backup without touching any files.

    def archive_raw(destination, options = {})
      load!(options)
      destination_directory = NauktisUtils::FileBrowser.ensure_valid_directory(destination)
      backup_name = NauktisUtils::FileBrowser.sanitize_name("#{@info_plist.last_backup_date.strftime('%Y_%m_%d')}_#{@info_plist.product_type}_iOS#{@info_plist.product_version}_#{@info_plist.serial_number}_raw")
      parent_folder = @backup_directory
      NauktisUtils::Archiver.new do
        add(parent_folder)
        destination(destination_directory)
        name(File.basename(backup_name))
      end
    end

    ##
    # Extracts the backup to +destination_directory+.

    def extract_to(destination_directory, options = {})
      load!(options)
      options = {name: 'full'}.merge(options)
      destination_directory = NauktisUtils::FileBrowser.ensure_valid_directory(destination_directory)
      backup_name = NauktisUtils::FileBrowser.sanitize_name("#{@info_plist.last_backup_date.strftime('%Y_%m_%d')}_#{@info_plist.product_type}_iOS#{@info_plist.product_version}_#{@info_plist.serial_number}_#{options[:name]}")
      parent_directory = File.expand_path(File.join(destination_directory, backup_name))
      raise "Backup destination already exists. #{parent_directory}" if File.exist? parent_directory
      FileUtils.mkdir(parent_directory)
      logger.info(self.class.name) { "Starting backup extraction in directory #{parent_directory}" }
      copy_files(destination_directory, options)
      add_files_with_extensions(destination_directory)
      logger.info(self.class.name) { "Backup extraction finished. #{IosBackupExtractor.file_count(parent_directory)} files extracted." }
      parent_directory
    end

    ##
    # Creates a tar archive of the backup with files extracted.

    def archive_to(destination_directory, options = {})
      load!(options)
      Dir.mktmpdir(nil, options[:temp_folder]) do |dir|
        parent_folder = extract_to(dir, options)
        logger.debug(self.class.name) { "Starting archiving of #{parent_folder}" }
        NauktisUtils::Archiver.new do
          add(parent_folder)
          destination(destination_directory)
          name(File.basename(parent_folder))
          compress(:bzip2) if options[:compress]
        end
      end
    end

    ##
    # Tells whether the backup is encrypted or not.

    def is_encrypted?
      @manifest_plist['IsEncrypted']
    end

    # Prints one line information about the backup
    def to_s
      @info_plist.to_s
    end

    private

    ##
    # Loads the backup.
    # This operation is required before performing any action

    def load!(options = {})
      unless @loaded
        logger.debug(self.class.name) { 'Loading backup' }
        logger.info(self.class.name) { "Files in the original backup directory #{IosBackupExtractor.file_count(@backup_directory)}" }

        if is_encrypted?
          logger.info(self.class.name) { 'Encrypted backup' }
          major, minor = info_plist.versions
          @keybag = Keybag.create_with_backup_manifest(@manifest_plist, options.fetch(:password), major, minor)
        end

        @loaded = true
      end
    end

    ##
    # Returns true if the backup should include the file with +domain+ and +file_path+.
    # This is useful for partial backups.

    def should_include?(domain, file_path, options)
      # Check filters
      return false unless options[:domain_filter].nil? or domain =~ options[:domain_filter]
      return false unless options[:file_path_filter].nil? or file_path =~ options[:file_path_filter]
      return false unless options[:domain_except_filter].nil? or not (domain =~ options[:domain_except_filter])
      return false unless options[:file_path_except_filter].nil? or not (file_path =~ options[:file_path_except_filter])
      true
    end

    def copy_file_from_backup(backup_file, destination)
      file_in, file_out = prepare_file_copy_from_backup(backup_file, destination)
      FileUtils.cp(file_in, file_out)
    end

    def copy_enc_file_from_backup(backup_file, destination, key)
      file_in, file_out = prepare_file_copy_from_backup(backup_file, destination)
      cipher = OpenSSL::Cipher::AES256.new(:CBC)
      cipher.decrypt
      cipher.key = key
      buf = ''
      File.open(file_out, 'wb') do |outf|
        File.open(file_in, 'rb') do |inf|
          while inf.read(4096, buf)
            outf << cipher.update(buf)
          end
          outf << cipher.final
        end
      end
    end

    def prepare_file_copy_from_backup(backup_file, destination)
      # Prepare the source file
      backup_file = File.join(@backup_directory, backup_file) unless backup_file.start_with?(@backup_directory)
      backup_file = File.expand_path(backup_file)
      raise "File #{backup_file} doesn't exist in your backup source" unless File.exists?(backup_file)

      # Prepare destination
      destination = File.expand_path(destination)

      # TODO do that only if a flag is set.
      if File.exists?(destination)
        # Handle case sensitivity issues.
        current = File.basename(destination)
        existing = Dir.entries(File.dirname(destination))
        if not existing.include?(current) and existing.any? { |e| e.downcase == current.downcase }
          newdestination = ''
          i = 0
          loop do
            i += 1
            newdestination = File.join(File.dirname(destination), "#{current}_#{'cs' * i}")
            break unless File.exists?(newdestination)
          end
          logger.warn(self.class.name) { "Case sensitivity issue with #{destination}. Using #{newdestination}" }
          destination = newdestination
        else
          raise "File #{backup_file} already exists at #{destination}"
        end
      end

      logger.debug(self.class.name) { "Copying #{backup_file} to #{destination}" }
      FileUtils.mkdir_p(File.dirname(destination))

      [backup_file, destination]
    end

    ##
    # Adds all files with extension to the backup

    def add_files_with_extensions(destination_directory)
      Dir.entries(@backup_directory).each do |entry|
        path = File.expand_path(File.join(@backup_directory, entry))
        unless FileTest.directory? path
          unless File.extname(path).empty?
            logger.info(self.class.name) { "Keeping #{File.basename(path)} in the backup." }
            FileUtils.cp(NauktisUtils::FileBrowser.ensure_valid_file(path), destination_directory)
          end
        end
      end
      raise "#{INFO_PLIST} was not added" unless File.exists?(File.join(destination_directory, INFO_PLIST))
    end
  end
end
