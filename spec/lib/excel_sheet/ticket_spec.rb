# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExcelSheet::Ticket do
  let(:ticket)   { create(:ticket) }
  let(:tag_name) { 'foo' }
  let(:instance) { described_class.new(title: 'some title', ticket_ids: [ticket.id], timezone: 'Europe/Berlin', locale: 'de-de') }

  before do
    Tag.tag_add(object: 'Ticket', item: tag_name, o_id: 1, created_by_id: 1)
  end

  describe '#ticket_header' do
    it 'has Tags once' do
      tags_count = instance.ticket_header.count { |elem| elem[:display] == 'Tags' }

      expect(tags_count).to eq 1
    end

    it 'has 32 column in default configuration' do
      tags_count = instance.ticket_header.count

      expect(tags_count).to eq 32
    end

    it 'all elements have width attribute' do
      expect(instance.ticket_header).to all(have_key(:width))
    end
  end
end
