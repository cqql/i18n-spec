require 'i18n-spec'

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

    invalid = false

    paths.each do |path|
      unless I18nSpec::LocaleFile.is_parseable? path
        invalid = true

        puts "#{path} is not parseable"

        next
      end

      begin
        locale_file = I18nSpec::LocaleFile.from_file(path)
      rescue I18nSpec::LocaleFile::MultipleTopLevelKeys
        invalid = true

        puts "#{path} has multiple top level keys"

        next
      end

      invalid_pluralization_keys = locale_file.invalid_pluralization_keys
      missing_pluralization_keys = locale_file.missing_pluralization_keys

      if invalid_pluralization_keys.any?
        invalid = true

        puts "#{path} has invalid pluralizations:"

        invalid_pluralization_keys.each do |key|
          puts "  - #{key}"
        end
      end

      if missing_pluralization_keys.any?
        invalid = true

        puts "#{path} has the following incomplete pluralizations:"

        missing_pluralization_keys.each do |key, missing_pluralizations|
          puts "  - \"#{key}\" misses"

          missing_pluralizations.each do |pluralization_key|
            puts "    - #{pluralization_key}"
          end
        end
      end
    end

    if invalid
      fail
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

    puts "Comparing locales to #{ARGV[1]}"
    puts

    default_locale = I18nSpec::LocaleFile.from_file(ARGV[1])
    any_locale_incomplete = false

    locale_files.each do |locale_path|
      locale_file = I18nSpec::LocaleFile.from_file(locale_path)

      if !locale_file.is_a_complete_translation_of? default_locale
        any_locale_incomplete = true

        puts "#{locale_path} is missing the following keys:"

        locale_file.missing_keys_from_locale(default_locale).each do |key|
          puts "  - #{key}"
        end
      end
    end

    if any_locale_incomplete
      fail
    else
      puts "All locales are complete"
    end
  end
end