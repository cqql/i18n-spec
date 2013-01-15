RSpec::Matchers.define :be_a_complete_translation_of do |default_locale_filepath|
  default_locale = I18nSpec::LocaleFile.from_file(default_locale_filepath)

  match do |path|
    locale_file = I18nSpec::LocaleFile.from_file(path)

    locale_file.is_a_complete_translation_of? default_locale
  end

  failure_message_for_should do |path|
    locale_file = I18nSpec::LocaleFile.from_file(path)

    "expected #{path} to include :\n- " << locale_file.missing_keys_from_locale(default_locale).join("\n- ")
  end
end