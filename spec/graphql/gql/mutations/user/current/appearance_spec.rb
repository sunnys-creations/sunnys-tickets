# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::Appearance, type: :graphql do
  let(:user) { create(:agent) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentAppearance($theme: EnumAppearanceTheme!) {
        userCurrentAppearance(theme: $theme) {
          success
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:variables) { { theme: 'light' } }

  def execute_graphql_query
    gql.execute(mutation, variables: variables)
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    context 'without valid theme' do
      let(:variables) { { theme: 'invalid' } }

      it 'returns an error' do
        expect(execute_graphql_query.error_message).to eq('Variable $theme of type EnumAppearanceTheme! was provided invalid value')
      end
    end

    context 'with valid theme' do
      it 'updates user profile appearance settings' do
        expect { execute_graphql_query }.to change { user.reload.preferences['theme'] }.from(nil).to('light')
      end
    end
  end
end
