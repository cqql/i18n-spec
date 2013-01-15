RSpec::Matchers.define :have_legacy_interpolations do
  match do |actual|
    IO.read(actual).should =~ /\{\{.+\}\}/
  end
end
