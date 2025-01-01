# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::State do

  def creates_with(zammad_structure)
    allow(import_object).to receive(:find_by).and_return(nil)
    allow(import_object).to receive(:new).with(zammad_structure).and_call_original

    expect_any_instance_of(import_object).to receive(:save)
    expect_any_instance_of(described_class).to receive(:reset_primary_key_sequence)
    start_import_test
  end

  def updates_with(zammad_structure)
    allow(import_object).to receive(:find_by).and_return(existing_object)

    expect(existing_object).to receive(:update!).with(zammad_structure)
    expect(import_object).not_to receive(:new)
    start_import_test
  end

  def load_state_json(file)
    json_fixture("import/otrs/state/#{file}")
  end

  let(:import_object)     { Ticket::State }
  let(:existing_object)   { instance_double(import_object) }
  let(:start_import_test) { described_class.new(object_structure) }

  context 'closed' do
    let(:object_structure) { load_state_json('default') }
    let(:zammad_structure) do
      {
        created_by_id:     1,
        updated_by_id:     1,
        active:            '1',
        state_type_id:     5,
        updated_at:        '2014-04-28 10:53:18',
        created_at:        '2014-04-28 10:53:18',
        name:              'closed successful',
        id:                '2',
        note:              'Ticket is closed successful.',
        ignore_escalation: true
      }
    end

    it 'creates' do
      creates_with(zammad_structure)
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end

  context 'open' do
    let(:object_structure) { load_state_json('open') }
    let(:zammad_structure) do
      {
        created_by_id:     1,
        updated_by_id:     1,
        active:            '1',
        state_type_id:     2,
        updated_at:        '2014-04-28 10:53:18',
        created_at:        '2014-04-28 10:53:18',
        name:              'open',
        id:                '4',
        note:              'Open tickets.',
        ignore_escalation: false
      }
    end

    it 'creates' do
      creates_with(zammad_structure)
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end

  context 'with removed state' do
    let(:object_structure) { load_state_json('removed') }

    it 'skips', :aggregate_failures do
      start_import_test

      expect(import_object).not_to receive(:new)
      expect(Ticket::State.find_by(name: 'removed')).to be_nil
    end
  end
end
