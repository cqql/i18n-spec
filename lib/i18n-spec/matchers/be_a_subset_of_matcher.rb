RSpec::Matchers.define :be_a_subset_of do |default_locale_filepath|
  match do |filepath|
    locale_file = I18nSpec::LocaleFile.from_file(filepath)
    default_locale = I18nSpec::LocaleFile.from_file(default_locale_filepath)

    @additional_keys = locale_file.keys - default_locale.keys

    @additional_keys.should be_empty
  end

  failure_message_for_should do |filepath|
    "expected #{filepath} to not include :\n- " << @additional_keys.join("\n- ")
  end
end