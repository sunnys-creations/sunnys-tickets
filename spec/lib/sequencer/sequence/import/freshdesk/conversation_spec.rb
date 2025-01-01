# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Freshdesk::Conversation, sequencer: :sequence do

  context 'when importing conversations from Freshdesk' do
    let(:inline_image_url) { 'https://eucattachment.freshdesk.com/inline/attachment?token=secret_token' }
    let(:resource) do
      {
        'body' => "<div style=\"font-family:-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif; font-size:14px\">\n<div dir=\"ltr\">Let's see if inline images work in a subsequent article:</div>\n<div dir=\"ltr\"><img src=\"#{inline_image_url}\" style=\"width: auto\" class=\"fr-fil fr-dib\" data-id=\"80012226853\"></div>\n</div>", 'body_text' => "Let's see if inline images work in a subsequent article:",
        'id' => 80_027_218_656,
        'incoming' => false,
        'private' => true,
        'user_id' => 80_014_400_475,
        'support_email' => nil,
        'source' => 2,
        'category' => 2,
        'to_emails' => ['info@zammad.org'],
        'from_email' => nil,
        'cc_emails' => [],
        'bcc_emails' => nil,
        'email_failure_count' => nil,
        'outgoing_failures' => nil,
        'created_at' => '2021-05-14T12:30:19Z',
        'updated_at' => '2021-05-14T12:30:19Z',
        'attachments' => [
          {
            'id'             => 80_012_226_885,
            'name'           => 'standalone_attachment.png',
            'content_type'   => 'image/png',
            'size'           => 11_447,
            'created_at'     => '2021-05-14T12:30:16Z',
            'updated_at'     => '2021-05-14T12:30:19Z',
            'attachment_url' => 'https://s3.eu-central-1.amazonaws.com/euc-cdn.freshdesk.com/data/helpdesk/attachments/production/80012226885/original/standalone_attachment.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=secret-amz-credential&X-Amz-Date=20210514T123300Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=750988d37a6f2f43830bfd19c895517aa051aa13b4ab26a1333369d414fef0be',
            'thumb_url'      => 'https://s3.eu-central-1.amazonaws.com/euc-cdn.freshdesk.com/data/helpdesk/attachments/production/80012226885/thumb/standalone_attachment.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=secret-amz-credential&X-Amz-Date=20210514T123300Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=40b5fe1d7d418bcbd1e639b273a1038c7a73781c16d9881c2f31a11c6bebfdf9'
          }
        ],
        'auto_response' => false,
        'ticket_id' => 1001,
        'source_additional_info' => nil
      }
    end
    let(:used_urls) do
      [
        'https://eucattachment.freshdesk.com/inline/attachment?token=secret_token',
        'https://s3.eu-central-1.amazonaws.com/euc-cdn.freshdesk.com/data/helpdesk/attachments/production/80012226885/original/standalone_attachment.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=secret-amz-credential&X-Amz-Date=20210514T123300Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=750988d37a6f2f43830bfd19c895517aa051aa13b4ab26a1333369d414fef0be',
      ]
    end

    let(:ticket) { create(:ticket) }
    let(:id_map) do
      {
        'Ticket' => {
          1001 => ticket.id,
        },
        'User'   => {
          80_014_400_475 => 1,
        }
      }
    end
    let(:process_payload) do
      {
        import_job:            build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:               false,
        resource:              resource,
        field_map:             {},
        id_map:                id_map,
        time_entry_available:  false,
        skip_initial_contacts: false,
      }
    end

    before do
      # Mock the attachment and inline image download requests.
      used_urls.each do |used_url|
        stub_request(:get, used_url).to_return(status: 200, body: '123', headers: {})
      end
    end

    shared_examples 'import article' do
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
          body: "<div>\n<div dir=\"ltr\">Let's see if inline images work in a subsequent article:</div>\n<div dir=\"ltr\"><img src=\"cid:#{attachment_list.first[:preferences]['Content-ID']}\" style=\"width: auto;\"></div>\n</div>",
        )
      end
    end

    include_examples 'import article'

    it 'updates already existing article' do
      expect do
        process(process_payload)
        process(process_payload)
      end.to change(Ticket::Article, :count).by(1)
    end

    it 'adds correct number of attachments' do
      process(process_payload)
      expect(Ticket::Article.last.attachments.size).to eq 2
    end

    it 'adds attachment content' do
      process(process_payload)
      expect(Ticket::Article.last.attachments.last).to have_attributes(
        'filename'    => 'standalone_attachment.png',
        'size'        => '3',
        'preferences' => {
          'Content-Type' => 'image/png',
          'resizable'    => false,
        }
      )
    end

    context 'when handling special inline images' do
      context 'when inline image source contains special urls (e.g. "cid:https://...")' do
        let(:inline_image_url) { 'cid:https://eucattachment.freshdesk.com/inline/attachment?token=secret_token' }

        include_examples 'import article'
      end

      context 'when inline image source contains broken urls' do
        let(:inline_image_url) { 'broken_image_url' }

        it 'skips image download with broken inline image url' do
          expect { process(process_payload) }.to change(Ticket::Article, :count).by(1)
        end

        it 'correct attributes for added article' do
          process(process_payload)
          expect(Ticket::Article.last).to have_attributes(
            to:   'info@zammad.org',
            body: "<div>\n<div dir=\"ltr\">Let's see if inline images work in a subsequent article:</div>\n<div dir=\"ltr\"><img src=\"broken_image_url\" style=\"width: auto;\"></div>\n</div>",
          )
        end
      end
    end
  end
end
