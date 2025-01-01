# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # search
  match api_path + '/search',           to: 'search#search_generic', via: %i[get post]
  match api_path + '/search/:objects',  to: 'search#search_generic', via: %i[get post]
end
