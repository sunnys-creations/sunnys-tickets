# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Freshdesk::Ticket, db_strategy: :reset, sequencer: :sequence do

  context 'when importing tickets from Freshdesk' do

    let(:group) { create(:group) }
    let(:resource) do
      {
        'cc_emails' => [],
        'fwd_emails' => [],
        'reply_cc_emails' => [],
        'ticket_cc_emails' => [],
        'fr_escalated' => false,
        'spam' => false,
        'email_config_id' => nil,
        'group_id' => 80_000_374_718,
        'priority' => 1,
        'requester_id' => 80_014_400_475,
        'responder_id' => 80_014_400_475,
        'source' => 3,
        'company_id' => nil,
        'status' => 2,
        'subject' => 'Inline Images Failing?',
        'association_type' => nil,
        'support_email' => nil,
        'to_emails' => ['info@zammad.org'],
        'product_id' => nil,
        'id' => 13,
        'type' => 'Incident',
        'due_by' => '2021-05-17T12:29:27Z',
        'fr_due_by' => '2021-05-15T12:29:27Z',
        'is_escalated' => false,
        'custom_fields' => {
          'cf_test_checkbox'   => true,
          'cf_custom_integer'  => 999,
          'cf_custom_dropdown' => 'key_2',
          'cf_custom_decimal'  => '1.1',
          'cf_not_existing'    => 'not_existing',
        },
        'created_at' => '2021-05-14T12:29:27Z',
        'updated_at' => '2021-05-14T12:30:19Z',
        'associated_tickets_count' => nil,
        'tags' => %w[example test],
        'description' => "<div style=\"font-family:-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif; font-size:14px\">\n<div dir=\"ltr\">Inline images in the first article might not be working, see following:</div>\n<div dir=\"ltr\"><img src=\"https://eucattachment.freshdesk.com/inline/attachment?token=secret_token\" style=\"width: auto\" class=\"fr-fil fr-dib\" data-id=\"80012226479\"></div>\n</div>", 'description_text' => 'Inline images in the first article might not be working, see following:'
      }

    end
    let(:field_map) do
      {
        'Ticket' => {
          'cf_test_checkbox'   => 'cf_test_checkbox',
          'cf_custom_integer'  => 'cf_custom_integer',
          'cf_custom_dropdown' => 'cf_custom_dropdown',
          'cf_custom_decimal'  => 'cf_custom_decimal'
        }
      }
    end
    let(:id_map) do
      {
        'User'  => {
          80_014_400_475 => owner.id,
        },
        'Group' => {
          80_000_374_718 => group.id,
        },
      }
    end
    let(:process_payload) do
      {
        import_job:            build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:               false,
        resource:              resource,
        field_map:             field_map,
        id_map:                id_map,
        time_entry_available:  true,
        skip_initial_contacts: false,
      }
    end
    let(:owner) { create(:agent, group_ids: [group.id]) }

    let(:ticket_get_response_payload) do
      attachment_payload = {
        'attachments' => [
          {
            'id'             => 80_012_226_885,
            'name'           => 'standalone_attachment.png',
            'content_type'   => 'image/png',
            'size'           => 11_447,
            'created_at'     => '2021-05-14T12:30:16Z',
            'updated_at'     => '2021-05-14T12:30:19Z',
            'attachment_url' => 'https://s3.eu-central-1.amazonaws.com/euc-cdn.freshdesk.com/data/helpdesk/attachments/production/80012226885/original/standalone_attachment.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=secret_amz_credential&X-Amz-Date=20210514T123300Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=750988d37a6f2f43830bfd19c895517aa051aa13b4ab26a1333369d414fef0be',
            'thumb_url'      => 'https://s3.eu-central-1.amazonaws.com/euc-cdn.freshdesk.com/data/helpdesk/attachments/production/80012226885/thumb/standalone_attachment.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=secret_amz_credential&X-Amz-Date=20210514T123300Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=40b5fe1d7d418bcbd1e639b273a1038c7a73781c16d9881c2f31a11c6bebfdf9'
          }
        ],
      }
      resource.merge(attachment_payload)
    end

    let(:used_urls) do
      [
        'https://eucattachment.freshdesk.com/inline/attachment?token=secret_token',
        'https://s3.eu-central-1.amazonaws.com/euc-cdn.freshdesk.com/data/helpdesk/attachments/production/80012226885/original/standalone_attachment.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=secret_amz_credential&X-Amz-Date=20210514T123300Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=750988d37a6f2f43830bfd19c895517aa051aa13b4ab26a1333369d414fef0be',
      ]
    end

    let(:imported_ticket) do
      {
        title:                    'Inline Images Failing?',
        note:                     nil,
        create_article_type_id:   5,
        create_article_sender_id: 2,
        article_count:            1,
        state_id:                 2,
        group_id:                 group.id,
        priority_id:              1,
        owner_id:                 owner.id,
        customer_id:              User.last.id,
        type:                     'Incident',
        cf_custom_dropdown:       'key_2',
        cf_custom_integer:        999,
        cf_test_checkbox:         true,
        cf_custom_decimal:        '1.1',
      }
    end

    let(:imported_article_attachments) do
      {
        'filename'    => 'standalone_attachment.png',
        'size'        => '3',
        'preferences' => {
          'Content-Type' => 'image/png',
          'resizable'    => false,
        }
      }
    end

    before do
      create(:object_manager_attribute_select, name:  'cf_custom_dropdown')
      create(:object_manager_attribute_integer, name: 'cf_custom_integer')
      create(:object_manager_attribute_boolean, name: 'cf_test_checkbox')
      create(:object_manager_attribute_text, name: 'cf_custom_decimal')
      ObjectManager::Attribute.migration_execute

      # Mock the attachment and inline image download requests.
      used_urls.each do |used_url|
        stub_request(:get, used_url).to_return(status: 200, body: '123', headers: {})
      end
      # Mock the ticket get request (Import::Freshdesk::Ticket::Fetch).
      stub_request(:get, 'https://yours.freshdesk.com/api/v2/tickets/13').to_return(status: 200, body: JSON.generate(ticket_get_response_payload), headers: {})

      # We only want to test here the Ticket API, so disable other modules in the sequence
      #   that make their own HTTP requests.
      custom_sequence = described_class.sequence.dup
      custom_sequence.delete('Import::Freshdesk::Ticket::TimeEntries')
      custom_sequence.delete('Import::Freshdesk::Ticket::Conversations')

      allow(described_class).to receive(:sequence) { custom_sequence }
    end

    it 'adds tickets' do
      expect { process(process_payload) }.to change(Ticket, :count).by(1)
    end

    it 'correct attributes for added ticket' do
      process(process_payload)
      expect(Ticket.last).to have_attributes(imported_ticket)
    end

    it 'correct tags for added ticket' do
      process(process_payload)
      expect(Ticket.last.tag_list).to eq(%w[example test])
    end

    it 'adds article with inline image' do
      expect { process(process_payload) }.to change(Ticket::Article, :count).by(1)
    end

    it 'correct attributes for added article' do
      process(process_payload)

      attachment_list = Store.list(
        object: 'Ticket::Article',
        o_id:   Ticket::Article.last.id,
      )

      expect(Ticket::Article.last).to have_attributes(
        to:   'info@zammad.org',
        body: "<div>\n<div dir=\"ltr\">Inline images in the first article might not be working, see following:</div>\n<div dir=\"ltr\"><img src=\"cid:#{attachment_list.first[:preferences]['Content-ID']}\" style=\"width: auto;\"></div>\n</div>",
      )
    end

    it 'adds correct number of attachments' do
      process(process_payload)
      expect(Ticket::Article.last.attachments.size).to eq 2
    end

    it 'adds attachment content' do
      process(process_payload)
      expect(Ticket::Article.last.attachments.last).to have_attributes(imported_article_attachments)
    end

    context 'when ticket is imported twice' do
      before do
        process(process_payload)
      end

      it 'updates first article for already existing ticket' do
        expect { process(process_payload) }.not_to change(Ticket::Article, :count)
      end

      it 'correct tags for added ticket' do
        process(process_payload)
        expect(Ticket.last.tag_list).to eq(%w[example test])
      end
    end

    context 'when importing without a type' do
      let(:resource) do
        super().merge(
          'type' => nil
        )
      end
      let(:imported_ticket) do
        super().merge(
          type: nil
        )
      end

      it 'correct attributes for added ticket' do
        process(process_payload)
        expect(Ticket.last).to have_attributes(imported_ticket)
      end
    end
  end
end
