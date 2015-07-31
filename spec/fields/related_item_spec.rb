require "spec_helper"

def mods_display_item(mods_record)
  ModsDisplay::RelatedItem.new(mods_record, ModsDisplay::Configuration::Base.new, double("controller"))
end

describe ModsDisplay::RelatedItem do
  before(:all) do
    @item = Stanford::Mods::Record.new.from_str("<mods><relatedItem><titleInfo>A Related Item</titleInfo></relatedItem></mods>", false).related_item
    @linked_item = Stanford::Mods::Record.new.from_str("<mods><relatedItem><titleInfo>A Related Item</titleInfo><location><url>http://library.stanford.edu/</url></location></relatedItem></mods>", false).related_item
    @collection = Stanford::Mods::Record.new.from_str("<mods><relatedItem><titleInfo>This is a Collection</titleInfo><typeOfResource collection='yes' /></relatedItem></mods>", false).related_item
    @display_label = Stanford::Mods::Record.new.from_str("<mods><relatedItem displayLabel='Special Item'><titleInfo>A Related Item</titleInfo></relatedItem></mods>", false).related_item
    @location = Stanford::Mods::Record.new.from_str("<mods><relatedItem><location>The Location</location></relatedItem></mods>", false).related_item
    @reference = Stanford::Mods::Record.new.from_str("<mods><relatedItem type='isReferencedBy'><titleInfo>The title</titleInfo><note>124</note><originInfo><dateOther>DATE</dateOther></originInfo></relatedItem></mods>", false).related_item
    @blank_item = Stanford::Mods::Record.new.from_str("<mods><relatedItem><titleInfo><title></title></titleInfo><location><url></url></location></relatedItem></mods>", false).related_item
    @multi_items = Stanford::Mods::Record.new.from_str("<mods><relatedItem><titleInfo><title>Library</title></titleInfo><location><url>http://library.stanford.edu</url></location></relatedItem><relatedItem><titleInfo><title>SDR</title></titleInfo><location><url>http://purl.stanford.edu</url></location></relatedItem></mods>", false).related_item
  end
  describe "label" do
    it "should default to Related Item" do
      expect(mods_display_item(@item).fields.first.label).to eq("Related item:")
    end
    it "should get the location label" do
      expect(mods_display_item(@location).fields.first.label).to eq("Location:")
    end
    it "should get the reference label" do
      expect(mods_display_item(@reference).fields.first.label).to eq("Referenced by:")
    end
    it "should get the displayLabel if available" do
      expect(mods_display_item(@display_label).fields.first.label).to eq("Special Item:")
    end
  end
  describe "fields" do
    it "should get a location if it is available" do
      fields = mods_display_item(@item).fields
      expect(fields.length).to eq(1)
      expect(fields.first.values).to eq(["A Related Item"])
    end
    it "should return a link if there is a location/url present" do
      fields = mods_display_item(@linked_item).fields
      expect(fields.length).to eq(1)
      expect(fields.first.values).to eq(["<a href='http://library.stanford.edu/'>A Related Item</a>"])
    end
    it "should not return any fields if the described related item is a collection" do
      expect(mods_display_item(@collection).fields).to eq([])
    end
    it "should not return empty links when there is no title or link" do
      expect(mods_display_item(@blank_item).fields).to eq([])
    end
    it "should concat the isReferencedBy related item title with other metadata" do
      fields = mods_display_item(@reference).fields
      expect(fields.length).to eq(1)
      expect(fields.first.values).to eq(["The title DATE 124"])
    end
    it "should collapse labels down into the same record" do
      fields = mods_display_item(@multi_items).fields
      expect(fields.length).to eq(1)
      expect(fields.first.label).to eq("Related item:")
      expect(fields.first.values.length).to eq(2)
      expect(fields.first.values.first).to match(/<a href=.*>Library<\/a>/) or
      expect(fields.first.values.last).to match(/<a href=.*>SDR<\/a>/)
    end
  end
end