module LocaleFileHelper
  def locale_file_with_content(content)
    create_locale "spec/fixtures/en.yml", content
  end

  def create_locale path, content
    I18nSpec::LocaleFile.new path, YAML.load(content)
  end
end

describe I18nSpec::LocaleFile do
  include LocaleFileHelper

  describe "#locale" do
    it "should return the locale of the file" do
      locale_file = locale_file_with_content("pt-BR:\n  hello: world")
      locale_file.locale.should == 'pt-BR'
    end
  end

  describe "#locale_tag" do
    it "returns an ISO::Tag based on the locale_code" do
      locale_file = locale_file_with_content("pt-BR:\n  hello: world")
      locale_file.locale_tag.should be_a(ISO::Tag)
      locale_file.locale_tag.language.code.should == 'pt'
      locale_file.locale_tag.region.code.should == 'BR'
    end
  end

  describe "#is_named_like_locale?" do
    it "should return true when the file is named like the contained locale" do
      locale_file = create_locale "spec/fixtures/en.yml", <<-YAML
en:
  save: "Save"
      YAML

      locale_file.is_named_like_locale?.should be true
    end

    it "should return false when the file is named like the contained locale" do
      locale_file = create_locale "spec/fixtures/en.yml", <<-YAML
de:
  save: "Speichern"
      YAML

      locale_file.is_named_like_locale?.should be false
    end
  end

  describe "#invalid_pluralization_keys" do
    it "should return nodes that contain at least one but not all needed pluralization keys" do
      locale_file = locale_file_with_content <<-YAML
en:
  animals:
    cats:
      one: "A cat"
      two: "Two cats"
      name: "Tommy"
      YAML

      locale_file.invalid_pluralization_keys.should include "animals.cats"
    end

    it "should not return nodes that do no contain any pluralization keys" do
      locale_file = locale_file_with_content <<-YAML
en:
  animals:
    birds:
      eagle: "Eagle"
      hawk: "Hawk"
      YAML

      locale_file.invalid_pluralization_keys.should_not include "animals.birds"
    end

    it "should not return nodes that are valid pluralization keys" do
      locale_file = locale_file_with_content <<-YAML
en:
  animals:
    elephants:
      one: "An elephant"
      other: "An elephant mob"
      YAML

      locale_file.invalid_pluralization_keys.should_not include "animals.elephants"
    end
  end

  describe "#missing_pluralization_keys" do
    it "should not include nodes that are not pluralizations at all" do
      locale_file = locale_file_with_content <<-YAML
en:
  cats:
    one: "A cat"
  dogs:
    big: "Labrador"
    small: "Dachshund"
      YAML

      locale_file.missing_pluralization_keys.should == { "cats" => ["other"]}
    end

    it "returns the parents that contain missing pluralizations in with the english rules" do
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
        'cats' => %w(other),
        'dogs' => %w(one)
      }
    end

    it "returns the parents that contain missing pluralizations in with the russian rules" do
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
        'dogs' => %w(few many),
        'birds' => %w(many)
      }
    end

    # Here the result should be empty because ja.cats is no pluralization because it does not even have one
    # pluralization key. If ja.cats was a pluralization every japanese key would be.
    it "returns the parents that contain missing pluralizations in with the japanese rules" do
      content = "ja:
        cats:
          one: A cat
        dogs:
          other: some dog
        birds: not really a pluralization"

      locale_file = locale_file_with_content(content)
      locale_file.missing_pluralization_keys.should == { }
    end

    it "returns an empty hash when all pluralizations are complete" do
      content = "ja:
        cats:
          other: one
        dogs:
          other: some
        birds: not really a pluralization"
      locale_file = locale_file_with_content(content)
      locale_file.missing_pluralization_keys.should == { }
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

  describe "#keys" do
    it "should return all saved translation keys" do
      english = locale_file_with_content <<-YAML
en:
  save: "Save"
  action:
    tag: "Tag"
      YAML

      english.keys.should == ["save", "action.tag"]
    end

    it "should treat pluralized keys as one key" do
      english = locale_file_with_content <<-YAML
en:
  animals:
    cats:
      one: "A cat"
      other: "Many cats"
    dogs:
      one: "A cat"
      other: "Some dogs"
    birds:
      name: "Heinrich"
      YAML

      english.keys.should == ["animals.cats", "animals.dogs", "animals.birds.name"]
    end
  end

  describe "#from_file" do
    it "should return a new instance of LocaleFile" do
      I18nSpec::LocaleFile.from_file("spec/fixtures/en.yml").should be_a I18nSpec::LocaleFile
    end

    it "should raise a SyntaxError if the file is not parseable" do
      expect { I18nSpec::LocaleFile.from_file("spec/fixtures/unparseable.yml") }.to raise_error SyntaxError
    end
  end

  describe "#is_parseable?" do
    it "should return true if the file is parseable" do
      I18nSpec::LocaleFile.is_parseable?("spec/fixtures/en.yml").should be true
    end

    it "should return false if the file is not parseable" do
      I18nSpec::LocaleFile.is_parseable?("spec/fixtures/unparseable.yml").should be false
    end
  end
end
