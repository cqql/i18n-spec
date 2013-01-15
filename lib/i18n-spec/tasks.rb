require 'i18n-spec'

I18nSpec::LOG_DETAIL_PREDICATE = "  - "

namespace :'i18n-spec' do
  desc "Checks the validity of a locale file"
  task :validate do
    if ARGV[1].nil?
      puts "You must specify a file path or a folder path"
      return
    elsif File.directory?(ARGV[1])
      paths = Dir.glob("#{ARGV[1]}/*.yml")
    elsif File.file? ARGV[1]
      paths = [ARGV[1]]
    else
      puts "#{ARGV[1]} is neither a valid path to a locale nor a folder containing locales"
    end

    paths.each do |path|
      heading path
      fatals, errors, warnings = [0, 0, 0]

      unless I18nSpec::LocaleFile.is_parseable? path
        log :fatal, 'could not be parsed'
        fatals += 1
        break
      end

      locale_file = I18nSpec::LocaleFile.from_file(path)

      unless locale_file.invalid_pluralization_keys.empty?
        log :error, 'invalid pluralization keys', format_array(locale_file.errors[:invalid_pluralization_keys])
        errors += 1
      end

      log :ok if fatals + errors + warnings == 0
    end
  end

  desc "Checks for missing translations between the default and the translated locale file"
  task :completeness do
    if ARGV[1].nil? || ARGV[2].nil?
      puts "You must specify a default locale file and translated file or a folder of translated files"
    elsif File.directory?(ARGV[2])
      locale_files = Dir.glob("#{ARGV[2]}/*.yml")
    else
      locale_files = [ARGV[2]]
    end

    default_locale = I18nSpec::LocaleFile.from_file(ARGV[1])
    any_locale_incomplete = false

    locale_files.each do |locale_path|
      heading locale_path

      locale_file = I18nSpec::LocaleFile.from_file(locale_path)

      if locale_file.is_a_complete_translation_of? default_locale
        log :complete
      else
        any_locale_incomplete = true

        locale_file.missing_keys_from_locale(default_locale).each { |miss| log :missing, miss }
      end
    end

    if any_locale_incomplete
      raise "There were incomplete locales."
    end
  end

  def log(level, msg='', detail=nil)
    puts "- *" << level.to_s.upcase << '* ' << msg 
    puts detail if detail
  end

  def heading(str='')
    puts "\n### " << str << "\n\n"
  end

  def format_array(array)
    [I18nSpec::LOG_DETAIL_PREDICATE, array.join(I18nSpec::LOG_DETAIL_PREDICATE)].join
  end

  def format_str(str)
    [I18nSpec::LOG_DETAIL_PREDICATE, str].join
  end
end