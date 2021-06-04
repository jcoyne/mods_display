require 'spec_helper'

def mods_display_access_condition(mods_record)
  ModsDisplay::AccessCondition.new(
    mods_record,
    ModsDisplay::Configuration::AccessCondition.new,
    double('controller')
  )
end

def mods_display_non_ignore_access_condition(mods_record)
  ModsDisplay::AccessCondition.new(
    mods_record,
    ModsDisplay::Configuration::AccessCondition.new { display! },
    double('controller')
  )
end

RSpec.describe ModsDisplay::AccessCondition do
  include AccessConditionFixtures

  describe 'labels' do
    let(:nodes) { Stanford::Mods::Record.new.from_str(restricted_access_fixture, false).accessCondition }

    it 'should normalize types and assign proper labels' do
      fields = mods_display_access_condition(nodes).fields
      expect(fields.length).to eq(1)
      expect(fields.first.label).to eq('Restriction on access:')
      fields.first.values.each_with_index do |value, index|
        expect(value).to match(/^Restrict Access Note#{index + 1}/)
      end
    end
  end

  describe 'fields' do
    before :all do
      @access_condition = Stanford::Mods::Record.new.from_str(simple_access_condition_fixture, false).accessCondition
      @restrict_condition = Stanford::Mods::Record.new.from_str(restricted_access_fixture, false).accessCondition
      @copyright_note = Stanford::Mods::Record.new.from_str(copyright_access_fixture, false).accessCondition
      @cc_license_note = Stanford::Mods::Record.new.from_str(cc_license_fixture, false).accessCondition
      @odc_license_note = Stanford::Mods::Record.new.from_str(odc_license_fixture, false).accessCondition
      @no_link_license_note = Stanford::Mods::Record.new.from_str(no_license_fixture, false).accessCondition
    end

    describe 'copyright' do
      it "should replace instances of '(c) copyright' with the HTML copyright entity" do
        fields = mods_display_access_condition(@copyright_note).fields
        expect(fields.length).to eq(1)
        expect(fields.first.values.length).to eq(1)
        expect(fields.first.values.first).to eq(
          'This is a &copy; Note.  Single instances of &copy; should also be replaced in these notes.'
        )
      end
    end
    describe 'licenses' do
      it 'should add the appropriate classes to the html around the license' do
        fields = mods_display_access_condition(@no_link_license_note).fields
        expect(fields.length).to eq(1)
        expect(fields.first.values.length).to eq(1)
        expect(fields.first.values.first).to match(%r{^<div class='unknown-something'>.*</div>$})
      end
      it 'should itentify and link CreativeCommons licenses properly' do
        fields = mods_display_access_condition(@cc_license_note).fields
        expect(fields.length).to eq(1)
        expect(fields.first.values.length).to eq(1)
        expect(fields.first.values.first).to include("<a href='http://creativecommons.org/licenses/by-sa/3.0/'>")
        expect(fields.first.values.first).to include(
          'This work is licensed under a Creative Commons Attribution-Share Alike 3.0 Unported License'
        )
      end
      it 'should itentify and link OpenDataCommons licenses properly' do
        fields = mods_display_access_condition(@odc_license_note).fields
        expect(fields.length).to eq(1)
        expect(fields.first.values.length).to eq(1)
        expect(fields.first.values.first).to include("<a href='http://opendatacommons.org/licenses/pddl/'>")
        expect(fields.first.values.first).to include(
          'This work is licensed under a Open Data Commons Public Domain Dedication and License (PDDL)'
        )
      end

      it 'should not attempt unknown license types' do
        fields = mods_display_access_condition(@no_link_license_note).fields
        expect(fields.length).to eq(1)
        expect(fields.first.values.length).to eq(1)
        expect(fields.first.values.first).to include(
          'This work is licensed under an Unknown License and will not be linked'
        )
        expect(fields.first.values.first).not_to include('<a.*>')
      end
    end
  end

  describe 'to_html' do
    let(:nodes) { Stanford::Mods::Record.new.from_str(simple_access_condition_fixture, false).accessCondition }

    it 'should ignore access conditions by default' do
      expect(mods_display_access_condition(nodes).to_html).to be_nil
    end
    it 'should not ignore the access condition when ignore is set to false' do
      html = mods_display_non_ignore_access_condition(nodes).to_html
      expect(html).to match %r{<dt.*>Access condition:</dt><dd>Access Condition Note</dd>}
    end
  end

  describe 'license condition' do
    subject(:field) { mods_display_non_ignore_access_condition(nodes) }
    let(:xml) { Nokogiri::XML("<xml><accessCondition type=\"license\" xlink:href=\"#{uri}\">junk</accessCondition></xml>") }
    let(:nodes) { xml.xpath('//accessCondition') }

    context 'for a uri with no class configured' do
      let(:uri) { 'https://creativecommons.org/publicdomain/zero/1.0/legalcode' }
      it 'renders a link' do
        expect(field.to_html).to eq "<dt title='License'>License:</dt><dd><div class=\"\">" \
          "<a href=\"https://creativecommons.org/publicdomain/zero/1.0/\">This work is licensed under a CC0 - 1.0</a></div></dd>"
      end
    end

    context 'for a uri with a configured class' do
      let(:uri) { 'https://creativecommons.org/licenses/by-nd/4.0/legalcode' }

      it 'renders a link' do
        expect(field.to_html).to eq "<dt title='License'>License:</dt><dd><div class=\"cc-by-nd\">" \
          "<a href=\"https://creativecommons.org/licenses/by-nd/4.0/\">" \
          "This work is licensed under a CC-BY-ND-4.0 Attribution-No Derivatives International</a></div></dd>"
      end
    end
  end
end
