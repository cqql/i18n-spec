RSpec::Matchers.define :have_one_top_level_namespace do
  match do |actual|
    begin
      I18nSpec::LocaleFile.from_file(actual)
    rescue I18nSpec::LocaleFile::MultipleTopLevelKeys
      false
    else
      true
    end
  end
end