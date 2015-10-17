module IosBackupExtractor
  class MBDB
    include NauktisUtils::Logging

    def initialize(manifest_location)
      parse(NauktisUtils::FileBrowser.ensure_valid_file(manifest_location))
    end

    def files
      @files
    end

    private
    # Retreive an integer (big-endian) from the current offset in the data.
    # Adjust the offset after.
    def get_integer(size)
      value = 0
      size.times do
        value = (value << 8) + @data[@offset].ord
        @offset += 1
      end
      value
    end

    # Retreive a string from the current offset in the data.
    # Adjust the offset after.
    def get_string
      if @data[@offset] == 0xFF.chr and @data[@offset + 1] == 0xFF.chr
        @offset += 2
        ''
      else
        length = get_integer(2)
        value = @data[@offset...(@offset + length)]
        @offset += length
        value
      end
    end

    # Parse the manifest file
    def parse(filename)
      # Set-up
      @files = Array.new
      @total_size = 0
      @data = File.open(filename, 'rb') { |f| f.read }
      @offset = 0
      raise 'This does not look like an MBDB file' if @data[0...4] != 'mbdb'
      @offset = 6 # We skip the header mbdb\5\0
      # Actual parsing
      while @offset < @data.size
        info = Hash.new
        info[:start_offset] = @offset
        info[:domain] = get_string # Domain name
        info[:file_path] = get_string # File path
        info[:link_target] = get_string # Absolute path for Symbolic Links
        info[:data_hash] = get_string
        info[:encryption_key] = get_string
        info[:mode] = get_integer(2)
        info[:type] = '?'
        info[:type] = 'l' if (info[:mode] & 0xE000) == 0xA000 # Symlink
        info[:type] = '-' if (info[:mode] & 0xE000) == 0x8000 # File
        info[:type] = 'd' if (info[:mode] & 0xE000) == 0x4000 # Directory
        @offset += 8 # We skip the inode numbers (uint64).
        info[:user_id] = get_integer(4)
        info[:group_id] = get_integer(4)
        info[:mtime] = get_integer(4) # File last modified time in Epoch format
        info[:atime] = get_integer(4) # File last accessed time in Epoch format
        info[:ctime] = get_integer(4) # File created time in Epoch format
        info[:file_size] = get_integer(8)
        info[:protection_class] = get_integer(1)
        info[:properties_number] = get_integer(1)
        info[:properties] = Hash.new
        info[:properties_number].times do
          propname = get_string
          propvalue = get_string
          info[:properties][propname] = propvalue
        end
        # Compute the ID of the file.
        fullpath = info[:domain] + '-' + info[:file_path]
        info[:file_id] = Digest::SHA1.hexdigest(fullpath)
        # We add the file to the list of files.
        @files << info
        # We accumulate the total size
        @total_size += info[:file_size]
      end
      logger.debug('Manifest Parser') {"#{IosBackupExtractor.thousand_separator(@files.size)} entries in the Manifest. Total size: #{IosBackupExtractor.thousand_separator(@total_size)} bytes."}
    end  
  end
end
