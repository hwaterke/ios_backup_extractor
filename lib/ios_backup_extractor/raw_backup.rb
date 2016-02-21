module IosBackupExtractor
  class RawBackup
    include NauktisUtils::Logging
    attr_reader :info_plist
    INFO_PLIST = 'Info.plist'
    MANIFEST_PLIST = 'Manifest.plist'

    def initialize(backup_directory)
      @backup_directory = NauktisUtils::FileBrowser.ensure_valid_directory(backup_directory)
      @info_plist = IosBackupExtractor.plist_to_hash(File.join(@backup_directory, INFO_PLIST))
      @manifest_plist = IosBackupExtractor.plist_to_hash(File.join(@backup_directory, MANIFEST_PLIST))
    end

    def extract_to(destination_directory, options = {})
      options = {name: 'full'}.merge(options)
      destination_directory = NauktisUtils::FileBrowser.ensure_valid_directory(destination_directory)
      backup_name = NauktisUtils::FileBrowser.sanitize_name("#{@info_plist['Last Backup Date'].strftime('%Y_%m_%d')}_#{@info_plist['Product Type']}_iOS#{@info_plist['Product Version']}_#{@info_plist['Serial Number']}_#{options[:name]}")
      parent_directory = File.expand_path(File.join(destination_directory, backup_name))
      FileUtils.mkdir(parent_directory)
      logger.info(self.class.name) { "Starting backup in temporary directory #{parent_directory}" }
      do_extract_to(parent_directory, options)
      parent_directory
    end

    def archive_to(destination_directory, options = {})
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

    def print_info
      ["Device Name", "Display Name", "Last Backup Date", "IMEI", "Serial Number", "Product Type", "Product Version", "iTunes Version"].each do |i|
        puts "#{i}: #{@info_plist[i]}"
      end
    end

    def to_s
      "#{@info_plist['Last Backup Date']} - #{@info_plist['Device Name']} - #{@info_plist['Serial Number']} (#{@info_plist['Product Type']} iOS #{@info_plist['Product Version']})"
    end
  end
end
