module IosBackupExtractor
  class Keybag
    def initialize(data)
      parseBinaryBlob(data)
    end


    def parseBinaryBlob(data)
      loopTLVBlocks(data) do |tag, value|
        puts "#{tag}: - #{value.size} - #{value}"
      end
    end

    def self.createWithBackupManifest(manifest, password)
      kb = Keybag.new(manifest["BackupKeyBag"].data)
      # TODO
      # raise "Cannot decrypt backup keybag. Wrong password ?" unless kb.unlockBackupKeybagWithPasscode(password)
      return kb
    end

    def loopTLVBlocks(data)
      i = 0
      while i + 8 <= data.size do
        tag = data[i..(i+4)]
        length = data[(i+4)..(i+8)].unpack('L>')[0]
        value = data[(i+8)..(i+8+length)]
        yield(tag, value)
        puts "#{tag} - #{length} - #{value}"
        i += 8 + length
      end
    end
  end
end