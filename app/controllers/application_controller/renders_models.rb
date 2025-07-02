# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::RendersModels
  extend ActiveSupport::Concern

  include CanPaginate

  private

  # model helper
  def model_create_render(object, params)

    clean_params = object.association_name_to_id_convert(params)
    clean_params = object.param_cleanup(clean_params, true)
    if object.included_modules.include?(ChecksCoreWorkflow)
      clean_params[:screen] = 'create'
    end

    # create object
    generic_object = object.new(clean_params)

    # set relations
    generic_object.associations_from_param(params)

    # save object
    generic_object.save!

    if response_expand?
      render json: generic_object.attributes_with_association_names, status: :created
      return
    end

    if response_full?
      render json: generic_object.class.full(generic_object.id), status: :created
      return
    end

    model_create_render_item(generic_object)
  end

  def model_create_render_item(generic_object)
    render json: generic_object.attributes_with_association_ids, status: :created
  end

  def model_update_render(object, params)

    # find object
    generic_object = object.find(params[:id])

    clean_params = object.association_name_to_id_convert(params)
    clean_params = object.param_cleanup(clean_params, true)
    if object.included_modules.include?(ChecksCoreWorkflow)
      clean_params[:screen] = 'edit'
    end

    generic_object.with_lock do

      # set relations
      generic_object.associations_from_param(params)

      # set attributes
      generic_object.update!(clean_params)

    end

    if response_expand?
      render json: generic_object.attributes_with_association_names, status: :ok
      return
    end

    if response_full?
      render json: generic_object.class.full(generic_object.id), status: :ok
      return
    end

    model_update_render_item(generic_object)
  end

  def model_update_render_item(generic_object)
    render json: generic_object.attributes_with_association_ids, status: :ok
  end

  def model_destroy_render(object, params)
    generic_object = object.find(params[:id])
    generic_object.destroy!
    model_destroy_render_item
  end

  def model_destroy_render_item()
    render json: {}, status: :ok
  end

  def model_show_render(object, params)

    if response_expand?
      generic_object = object.find(params[:id])
      render json: generic_object.attributes_with_association_names, status: :ok
      return
    end

    if response_full?
      render json: object.full(params[:id]), status: :ok
      return
    end

    model_show_render_item(object.find(params[:id]))
  end

  def model_show_render_item(generic_object)
    render json: generic_object.attributes_with_association_ids, status: :ok
  end

  def model_index_render(object, params)
    paginate_with(default: 500)

    sql_helper = ::SqlHelper.new(object: object)
    sort_by    = sql_helper.get_sort_by(params, 'id')
    order_by   = sql_helper.get_order_by(params, 'ASC')
    order_sql  = sql_helper.get_order(sort_by, order_by)

    generic_objects = object.reorder(Arel.sql(order_sql)).offset(pagination.offset).limit(pagination.limit)

    if response_expand?
      list = generic_objects.map(&:attributes_with_association_names)
      render json: list, status: :ok
      return
    end

    if response_full?
      assets = {}
      item_ids = []
      generic_objects.each do |item|
        item_ids.push item.id
        assets = item.assets(assets)
      end
      render json: {
        record_ids:  item_ids,
        assets:      assets,
        total_count: object.count
      }, status: :ok
      return
    end

    generic_objects_with_associations = generic_objects.map(&:attributes_with_association_ids)
    model_index_render_result(generic_objects_with_associations)
  end

  def model_index_render_result(generic_objects)
    render json: generic_objects, status: :ok
  end

  def model_references_check(object, params)
    generic_object = object.find(params[:id])
    result = Models.references(object, generic_object.id)
    return false if result.blank?

    raise Exceptions::UnprocessableEntity, __('Can\'t delete, object has references.')
  rescue => e
    raise Exceptions::UnprocessableEntity, e
  end

  def model_search_render(object, params)
    paginate_with(max: 200, default: 50)

    generic_objects = object.search(
      query:            params[:query] || params[:term],
      condition:        params[:condition],
      ids:              params[:ids],
      role_ids:         params[:role_ids],
      group_ids:        params[:group_ids],
      permissions:      params[:permissions],
      only_total_count: response_only_total_count?,
      sort_by:          params[:sort_by],
      order_by:         params[:order_by],
      offset:           pagination.offset,
      limit:            pagination.limit,
      current_user:     current_user,
      full:             true,
      with_total_count: true,
    ) || { objects: [], total_count: 0 }

    if response_only_total_count?
      model_search_render_result_only_total_count(generic_objects[:total_count])
    elsif response_full?
      model_search_render_result_full(generic_objects)
    elsif response_expand?
      model_search_render_result_expand(generic_objects)
    elsif params[:label] || params[:term]
      model_search_render_result_label(object, generic_objects)
    else
      result = generic_objects[:objects].map(&:attributes_with_association_ids)
      if response_with_total_count?
        result = {
          records:     result,
          total_count: generic_objects[:total_count],
        }
      end

      model_index_render_result(result)
    end
  end

  def model_search_render_result_only_total_count(total)
    render json: {
      total_count: total,
    }, status: :ok
  end

  def model_search_render_result_full(generic_objects)
    assets = {}
    item_ids = []
    generic_objects[:objects].each do |item|
      item_ids.push item.id
      assets = item.assets(assets)
    end
    render json: {
      record_ids:  item_ids,
      assets:      assets,
      total_count: generic_objects[:total_count],
    }, status: :ok
  end

  def model_search_render_result_expand(generic_objects)
    result = generic_objects[:objects].map(&:attributes_with_association_names)
    if response_with_total_count?
      result = {
        records:     result,
        total_count: generic_objects[:total_count],
      }
    end

    render json: result, status: :ok
  end

  def model_search_render_result_label(object, generic_objects)
    result = generic_objects[:objects].map do |row|
      realname = row.try(:fullname, recipient_line: true) || row.try(:fullname) || row.try(:name) || row.try(:id)
      value    = row.try(:email) || realname

      if params[:term] && object.column_names.include?('active')
        { id: row.id, label: realname, value: value, inactive: !row.active }
      else
        { id: row.id, label: realname, value: realname }
      end
    end

    if response_with_total_count?
      result = {
        records:     result,
        total_count: generic_objects[:total_count],
      }
    end

    render json: result
  end

end
