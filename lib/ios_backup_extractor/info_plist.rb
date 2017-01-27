class InfoPlist
  DEVICE_NAME = 'Device Name'
  DISPLAY_NAME = 'Display Name'
  IMEI = 'IMEI'
  ITUNES_VERSION = 'iTunes Version'
  LAST_BACKUP_DATE = 'Last Backup Date'
  PRODUCT_TYPE = 'Product Type'
  PRODUCT_VERSION = 'Product Version'
  SERIAL_NUMBER = 'Serial Number'

  TAGS = [DEVICE_NAME, DISPLAY_NAME, IMEI, ITUNES_VERSION, LAST_BACKUP_DATE, PRODUCT_TYPE, PRODUCT_VERSION, SERIAL_NUMBER]

  def initialize(file)
    raise 'Info.plist does not exist' unless File.exist?(file)
    @infos = IosBackupExtractor.plist_file_to_hash(file)
  end

  TAGS.each do |tag|
    define_method(tag.gsub(/\s+/, '_').downcase.to_sym) do
      @infos.fetch(tag)
    end
  end

  def versions
    product_version.scan(/\d+/).map {|i| i.to_i}
  end

  def has?(key)
    @infos.has_key?(key)
  end

  def details
    TAGS.each do |tag|
      puts "#{tag}: #{@infos.fetch(tag)}"
    end
  end

  def to_s
    "#{last_backup_date} - #{device_name} - #{serial_number} (#{product_type} iOS #{product_version})"
  end
end
