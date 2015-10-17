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
          infos = IosBackupExtractor.plist_to_hash(path)
          continue unless infos.has_key? 'Product Version'
          if infos['Product Version'][0] <= '3'
            @backups << RawBackup3.new(File.dirname(path))
          else
            @backups << RawBackup4.new(File.dirname(path))
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
