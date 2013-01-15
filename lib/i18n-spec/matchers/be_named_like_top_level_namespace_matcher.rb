RSpec::Matchers.define :be_named_like_top_level_namespace do
  match do |actual|
    locale_file = I18nSpec::LocaleFile.from_file(actual)
    locale_file.is_named_like_locale?
  end
end