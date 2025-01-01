# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class RecentViewController < ApplicationController
  prepend_before_action :authentication_check

=begin

Resource:
GET /api/v1/recent_viewed

Response:
{
  ...
}

Test:
curl http://localhost/api/v1/recent_view -v -u #{login}:#{password} -H "Content-Type: application/json" -X GET

=end

  def index
    recent_viewed = RecentView.list(current_user, 10)

    if response_expand?
      list = recent_viewed.map(&:attributes_with_association_names)
      render json: list, status: :ok
      return
    end

    if response_full?
      assets = {}
      item_ids = []
      recent_viewed.each do |item|
        item_ids.push item.id
        assets = item.assets(assets)
      end
      render json: {
        record_ids: item_ids,
        assets:     assets,
      }, status: :ok
      return
    end

    all = recent_viewed.map(&:attributes_with_association_ids)
    render json: all, status: :ok
  end

=begin

Resource:
POST /api/v1/recent_viewed

Payload:
{
  "object": "Ticket",
  "o_id": 123,
}

Response:
{}

Test:
curl http://localhost/api/v1/recent_view -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"object": "Ticket","o_id": 123}'

=end

  def create

    RecentView.log(params[:object], params[:o_id], current_user)

    # return result
    render json: { message: 'ok' }
  end

end
