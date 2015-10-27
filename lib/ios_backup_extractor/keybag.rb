module IosBackupExtractor
  class Keybag
    include NauktisUtils::Logging
    KEYBAG_TYPES = ["System", "Backup", "Escrow", "OTA (icloud)"]
    CLASSKEY_TAGS = ['UUID', 'CLAS', 'WRAP', 'WPKY', 'KTYP', 'PBKY']
    WRAP_DEVICE = 1
    WRAP_PASSCODE = 2

    def initialize(data)
      parseBinaryBlob(data)
    end

    def parseBinaryBlob(data)
      @classKeys = {}
      @attributes = {}
      currentClass = {}
      loopTLVBlocks(data) do |tag, value|
        if value.size == 4
          value = value.unpack("L>")[0]
        end
        if tag == 'TYPE'
          @type = value & 0x3FFFFFFF # Ignore the flags
          raise "Error: Keybag type #{@type} > 3" if @type > 3
          logger.debug(self.class){"Keybag of type #{KEYBAG_TYPES[@type]}"}
        end
        @uuid = value if tag == 'UUID' and @uuid.nil?
        @wrap = value if tag == 'WRAP' and @wrap.nil?
        currentClass = {} if tag == 'UUID' # New class starts by the UUID tag.
        currentClass[tag] = value if CLASSKEY_TAGS.include?(tag)
        @classKeys[currentClass['CLAS'] & 0xF] = currentClass if currentClass.has_key?('CLAS')
        @attributes[tag] = value
      end
    end

    def unlockBackupKeybagWithPasscode(password)
      raise "This is not a backup keybag" unless @type == 1 or @type == 2
      unwrapClassKeys(getPasscodekeyFromPasscode(password))
    end

    def unwrapClassKeys(passcodekey)
      @classKeys.each_value do |classkey|
        k = classkey['WPKY']
        if classkey['WRAP'] & WRAP_PASSCODE > 0
          k = AESKeyWrap.unwrap!(classkey["WPKY"].to_s, passcodekey)
          classkey["KEY"] = k
        end
      end
    end

    def unwrapKeyForClass(protection_class, persistent_key)
      raise "Keybag key #{protection_class} missing or locked" unless @classKeys.has_key?(protection_class) and @classKeys[protection_class].has_key?('KEY')
      raise "Invalid key length" unless persistent_key.length == 0x28
      AESKeyWrap.unwrap!(persistent_key, @classKeys[protection_class]['KEY'])
    end

    def getPasscodekeyFromPasscode(password)
      raise "This is not a backup/icloud keybag" unless @type == 1 or @type == 3
      OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, @attributes['SALT'], @attributes['ITER'], 32)
    end

    def self.createWithBackupManifest(manifest, password)
      kb = Keybag.new(manifest["BackupKeyBag"])
      kb.unlockBackupKeybagWithPasscode(password)
      kb.print_info
      kb
    end

    def loopTLVBlocks(data)
      i = 0
      while i + 8 <= data.size do
        tag = data[i...(i+4)].to_s
        length = data[(i+4)...(i+8)].unpack('L>')[0]
        value = data[(i+8)...(i+8+length)]
        yield(tag, value)
        i += 8 + length
      end
    end

    def print_info
      puts "== Keybag"
      puts "Keybag type: #{KEYBAG_TYPES[@type]} keybag (#{@type})"
      puts "Keybag version: #{@attributes['VERS']}"
      puts "Keybag iterations: #{@attributes['ITER']}, iv=#{@attributes['SALT'].unpack('H*')}"
      puts "Keybag UUID: #{@uuid.unpack('H*')}"
    end
  end
end
