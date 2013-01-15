RSpec::Matchers.define :be_parseable do
  match do |actual|
    begin
      I18nSpec::LocaleFile.from_file actual

      true
    rescue SyntaxError => e
      @exception = e

      false
    end
  end

  failure_message_for_should do |filepath|
    "expected #{filepath} to be parseable but got :\n- #{@exception}"
  end
end