module LocaleFileHelper
  def locale_file_with_content(content)
    locale_file = I18nSpec::LocaleFile.new('test.yml')
    locale_file.should_receive(:content).and_return(content)
    locale_file
  end
end

describe I18nSpec::LocaleFile do
  include LocaleFileHelper

  describe "#locale_code" do
    it "returns the first key of the file" do
      locale_file = locale_file_with_content("pt-BR:\n  hello: world")
      locale_file.locale_code.should == 'pt-BR'
    end
  end

  describe "#locale" do
    it "returns an ISO::Tag based on the locale_code" do
      locale_file = locale_file_with_content("pt-BR:\n  hello: world")
      locale_file.locale.should be_a(ISO::Tag)
      locale_file.locale.language.code.should == 'pt'
      locale_file.locale.region.code.should   == 'BR'
    end
  end

  describe "#is_parseable?" do
    context "when YAML is parseable" do
      let(:locale_file) { locale_file_with_content("en:\n  hello: world") }

      it "returns true" do
        locale_file.is_parseable?.should == true
      end
    end

    context "when YAML is NOT parseable" do
      let(:locale_file) { locale_file_with_content("<This isn't YAML>: foo: bar:") }

      it "returns false" do
        locale_file.is_parseable?.should == false
      end

      it "adds an :unparseable error" do
        locale_file.is_parseable?
        locale_file.errors[:unparseable].should_not be_nil
      end
    end
  end

  describe "#pluralizations" do
    let(:content) {
      "en:
        cats:
          one: one
          two: two
          three: three
        dogs:
          one: one
          some: some
        birds:
          penguins: penguins
          doves: doves"}

    it "returns the leaf where one of the keys is a pluralization key" do
      locale_file = locale_file_with_content(content)
      locale_file.pluralizations.should == {
        'en.cats' => {'one' => 'one', 'two' => 'two', 'three' => 'three'},
        'en.dogs' => {'one' => 'one', 'some' => 'some'},
      }
    end
  end

  describe "#invalid_pluralization_keys" do
    let(:content) {
      "en:
        cats:
          one: one
          two: two
          tommy: tommy
          tabby: tabby
        dogs:
          one: one
          some: some
        birds:
          zero: zero
          other: other"}
      let(:locale_file) { locale_file_with_content(content) }

    it "returns the parent that contains invalid pluralizations" do
      locale_file.invalid_pluralization_keys.size.should == 2
      locale_file.invalid_pluralization_keys.should be_include 'en.cats'
      locale_file.invalid_pluralization_keys.should be_include 'en.dogs'
      locale_file.invalid_pluralization_keys.should_not be_include 'en.birds'
    end

    it "adds a :invalid_pluralization_keys error with each invalid key" do
      locale_file.invalid_pluralization_keys
      locale_file.invalid_pluralization_keys.size.should == 2
      locale_file.invalid_pluralization_keys.should be_include 'en.cats'
      locale_file.invalid_pluralization_keys.should be_include 'en.dogs'
      locale_file.invalid_pluralization_keys.should_not be_include 'en.birds'
    end
  end

  describe "#missing_pluralization_keys" do
    it "returns the parents that containts missing pluralizations in with the english rules" do
      content = "en:
        cats:
          one: one
        dogs:
          other: other
        birds:
          one: one
          other: other"
      locale_file = locale_file_with_content(content)
      locale_file.missing_pluralization_keys.should == {
        'en.cats' => %w(other),
        'en.dogs' => %w(one)
      }
      locale_file.errors[:missing_pluralization_keys].should_not be_nil
    end

    it "returns the parents that containts missing pluralizations in with the russian rules" do
      content = "ru:
        cats:
          one: one
          few: few
          many: many
          other: other
        dogs:
          one: one
          other: some
        birds:
          zero: zero
          one: one
          few: few
          other: other"
      locale_file = locale_file_with_content(content)
      locale_file.missing_pluralization_keys.should == {
        'ru.dogs'  => %w(few many),
        'ru.birds' => %w(many)
      }
      locale_file.errors[:missing_pluralization_keys].should_not be_nil
    end

    it "returns the parents that containts missing pluralizations in with the japanese rules" do
      content = "ja:
        cats:
          one: one
        dogs:
          other: some
        birds: not really a pluralization"
      locale_file = locale_file_with_content(content)
      locale_file.missing_pluralization_keys.should == { 'ja.cats' => %w(other) }
      locale_file.errors[:missing_pluralization_keys].should_not be_nil
    end

    it "returns an empty hash when all pluralizations are complete" do
      content = "ja:
        cats:
          other: one
        dogs:
          other: some
        birds: not really a pluralization"
      locale_file = locale_file_with_content(content)
      locale_file.missing_pluralization_keys.should == {}
      locale_file.errors[:missing_pluralization_keys].should be_nil
    end
  end

  describe "#is_a_complete_translation_of?" do
    let(:locale_file) { locale_file_with_content <<-YAML }
de:
  save: "Speichern"
  edit: "Bearbeiten"
    YAML

    it "should return true when the locale file is a super set of the given locale file" do
      super_set = locale_file_with_content <<-YAML
en:
  save: "Save"
  edit: "Edit"
      YAML

      locale_file.is_a_complete_translation_of?(super_set).should be true
    end

    it "should return false when the locale file is a subset of the given locale file" do
      subset = locale_file_with_content <<-YAML
en:
  save: "Save"
  edit: "Edit"
  view: "View"
      YAML

      locale_file.is_a_complete_translation_of?(subset).should be false
    end
  end

  describe "#missing_keys_from_locale" do
    it "should return an array of keys that are missing in the locale file when compared to the given one" do
      english = locale_file_with_content <<-YAML
en:
  save: "Save"
  edit: "Edit"
  action:
    add: "Add"
    tag: "Tag"
      YAML

      german = locale_file_with_content <<-YAML
de:
  save: "Speichern"
  action:
    tag: "Markieren"
      YAML

      german.missing_keys_from_locale(english).should =~ ["edit", "action.add"]
    end
  end
end
