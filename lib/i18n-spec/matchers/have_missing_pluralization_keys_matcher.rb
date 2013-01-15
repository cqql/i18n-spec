RSpec::Matchers.define :have_missing_pluralization_keys do
  match do |actual|
    @locale_file = I18nSpec::LocaleFile.from_file(actual)

    @locale_file.missing_pluralization_keys.any?
  end

  failure_message_for_should_not do |filepath|
    missing_keys = []

    @locale_file.missing_pluralization_keys.each do |node, missing_pluralizations|
      missing_pluralizations.each do |pluralization|
        missing_keys << [node, pluralization].join('.')
      end
    end

    "expected #{filepath} to contain the following pluralization keys :\n- " << missing_keys.join("\n- ")
  end
end
