module IosBackupExtractor
  class BackupRetriever
    include NauktisUtils::Logging
    attr_reader :backups

    def search
      search_in(mobilesync)
    end

    def search_in(directory)
      @backups = []
      directory = NauktisUtils::FileBrowser.ensure_valid_directory(directory)
      logger.debug('Retriever') {"Retrieving iDevice backup files in #{directory}."}
      NauktisUtils::FileBrowser.each_file(directory) do |path|
        if File.basename(path) == 'Info.plist'
          infos = InfoPlist.new(path)
          continue unless infos.has? InfoPlist::PRODUCT_VERSION
          major = infos.versions.first
          if major <= 3
            raise 'iOS 3 backups are not supported'
          elsif major < 10
            @backups << RawBackup4.new(File.dirname(path))
          else
            @backups << RawBackup10.new(File.dirname(path))
          end
        end
      end
      self
    end

    private
    def mobilesync
      if RUBY_PLATFORM =~ /darwin/
        "#{ENV['HOME']}/Library/Application Support/MobileSync/Backup"
      else
        "#{ENV['APPDATA']}/Apple Computer/MobileSync/Backup/"
      end
    end
  end
end
