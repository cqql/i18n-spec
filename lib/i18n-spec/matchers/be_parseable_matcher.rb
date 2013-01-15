RSpec::Matchers.define :be_parseable do
  match do |actual|
    begin
      I18nSpec::LocaleFile.from_file actual
    rescue SyntaxError => e
      @exception = e

      false
    else
      true
    end
  end

  failure_message_for_should do |filepath|
    "expected #{filepath} to be parseable but got :\n- #{@exception}"
  end
end