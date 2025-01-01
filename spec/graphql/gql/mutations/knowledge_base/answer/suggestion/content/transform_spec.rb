# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::KnowledgeBase::Answer::Suggestion::Content::Transform, current_user_id: 1, type: :graphql do
  context 'when fetching content', authenticated_as: :agent do
    let(:agent)    { create(:agent) }
    let(:customer) { create(:customer) }

    let(:knowledge_base_answer) { create(:knowledge_base_answer, :published, :with_image, :with_attachment) }
    let(:knowledge_base_answer_translation) { knowledge_base_answer.translation }

    let(:mutation) do
      <<~MUTATION
        mutation knowledgeBaseAnswerSuggestionContentTransform(
          $translationId: ID!
          $formId: FormId!
        ) {
          knowledgeBaseAnswerSuggestionContentTransform(
            translationId: $translationId
            formId: $formId
          ) {
            body
            attachments {
              id
              name
              size
              type
              preferences
            }
            errors {
              message
              field
            }
          }
        }
      MUTATION
    end

    let(:variables) { { translationId: Gql::ZammadSchema.id_from_object(knowledge_base_answer_translation), formId: '5570fac8-8868-40b7-89e7-1cdabbd954ba' } }

    before do
      gql.execute(mutation, variables: variables)
    end

    context 'with authenticated session' do
      let(:copied_attachments) { Store.list(object: 'UploadCache', o_id: '5570fac8-8868-40b7-89e7-1cdabbd954ba') }

      it 'converts inline images to base64 data' do
        expect(gql.result.data[:body]).to include('src="data:image/jpeg;base64,')
      end

      it 'contains attachments' do
        expect(gql.result.data[:attachments]).to match_array(include(
                                                               id:          Gql::ZammadSchema.id_from_object(copied_attachments.first),
                                                               name:        copied_attachments.first.filename,
                                                               size:        copied_attachments.first.size.to_i,
                                                               type:        copied_attachments.first.preferences['Content-Type'],
                                                               preferences: copied_attachments.first.preferences,
                                                             ))
      end

      context 'with not existing translation' do
        let(:variables) { { translationId: Gql::ZammadSchema.id_from_object(knowledge_base_answer), formId: '5570fac8-8868-40b7-89e7-1cdabbd954ba' } }

        it 'raises an error' do
          expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'without proper permissions', authenticated_as: :admin do
      let(:admin) { create(:admin_only) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without authenticated session', authenticated_as: :customer do
      it 'fails with error type' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
