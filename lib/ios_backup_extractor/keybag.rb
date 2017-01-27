module IosBackupExtractor
  class Keybag
    include NauktisUtils::Logging
    KEYBAG_TYPES = ['System', 'Backup', 'Escrow', 'OTA (icloud)']
    CLASSKEY_TAGS = %w(UUID CLAS WRAP WPKY KTYP PBKY)
    WRAP_DEVICE = 1
    WRAP_PASSCODE = 2

    def initialize(data, version_major, version_minor)
      @version_major = version_major
      @version_minor = version_minor
      parse_binary_blob(data)
    end

    def parse_binary_blob(data)
      @class_keys = {}
      @attributes = {}
      current_class = {}
      loop_tlv_blocks(data) do |tag, value|
        if value.size == 4
          value = value.unpack('L>')[0]
        end
        if tag == 'TYPE'
          @type = value & 0x3FFFFFFF # Ignore the flags
          raise "Error: Keybag type #{@type} > 3" if @type > 3
          logger.debug(self.class){"Keybag of type #{KEYBAG_TYPES[@type]}"}
        end
        @uuid = value if tag == 'UUID' and @uuid.nil?
        @wrap = value if tag == 'WRAP' and @wrap.nil?
        current_class = {} if tag == 'UUID' # New class starts by the UUID tag.
        current_class[tag] = value if CLASSKEY_TAGS.include?(tag)
        @class_keys[current_class['CLAS'] & 0xF] = current_class if current_class.has_key?('CLAS')
        @attributes[tag] = value
      end
    end

    def unlock_backup_keybag_with_passcode(password)
      raise 'This is not a backup keybag' unless @type == 1 or @type == 2
      unwrap_class_keys(get_passcode_key_from_passcode(password))
    end

    def unwrap_class_keys(passcodekey)
      @class_keys.each_value do |classkey|
        k = classkey['WPKY']
        if classkey['WRAP'] & WRAP_PASSCODE > 0
          k = AESKeyWrap.unwrap!(classkey['WPKY'].to_s, passcodekey)
          classkey['KEY'] = k
        end
      end
    end

    def unwrap_key_for_class(protection_class, persistent_key)
      raise "Keybag key #{protection_class} missing or locked" unless @class_keys.has_key?(protection_class) and @class_keys[protection_class].has_key?('KEY')
      raise 'Invalid key length' unless persistent_key.length == 0x28
      AESKeyWrap.unwrap!(persistent_key, @class_keys[protection_class]['KEY'])
    end

    def get_passcode_key_from_passcode(password)
      raise 'This is not a backup/icloud keybag' unless @type == 1 or @type == 3

      if @version_major == 10 && @version_minor < 2
        return OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, @attributes['SALT'], @attributes['ITER'], 32)
      end

      # Version >= 10.2
      digest = OpenSSL::Digest::SHA256.new
      len = digest.digest_length
      kek = OpenSSL::PKCS5.pbkdf2_hmac(password, @attributes['DPSL'], @attributes['DPIC'], len, digest)
      OpenSSL::PKCS5.pbkdf2_hmac_sha1(kek, @attributes['SALT'], @attributes['ITER'], 32)
    end

    ##
    # Creates a new Keybag

    def self.create_with_backup_manifest(manifest, password, version_major, version_minor)
      kb = Keybag.new(manifest['BackupKeyBag'], version_major, version_minor)
      kb.unlock_backup_keybag_with_passcode(password)
      kb
    end

    ##
    # Prints information about the Keybag

    def print_info
      puts '== Keybag'
      puts "Keybag type: #{KEYBAG_TYPES[@type]} keybag (#{@type})"
      puts "Keybag version: #{@attributes['VERS']}"
      puts "Keybag iterations: #{@attributes['ITER']}, iv=#{@attributes['SALT'].unpack('H*')[0]}"
      puts "Keybag UUID: #{@uuid.unpack('H*')[0]}"
    end

    private

    ##
    # Parses a binary blob and extracts the tags and data.

    def loop_tlv_blocks(data)
      i = 0
      while i + 8 <= data.size do
        tag = data[i...(i+4)].to_s
        length = data[(i+4)...(i+8)].unpack('L>')[0]
        value = data[(i+8)...(i+8+length)]
        yield(tag, value)
        i += 8 + length
      end
    end
  end
end
