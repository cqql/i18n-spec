RSpec::Matchers.define :be_a_complete_translation_of do |default_locale_filepath|
  match do |filepath|
    locale_file = I18nSpec::LocaleFile.new(filepath)
    default_locale = I18nSpec::LocaleFile.new(default_locale_filepath)

    locale_file.is_a_complete_translation_of? default_locale
  end

  failure_message_for_should do |filepath|
    "expected #{filepath} to include :\n- " << @misses.join("\n- ")
  end
end