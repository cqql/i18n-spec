RSpec::Matchers.define :have_a_valid_locale do
  match do |actual|
    locale_file = I18nSpec::LocaleFile.from_file(actual)
    locale_file.locale_tag.valid?
  end
end
