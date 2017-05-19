module Strapi
  module ControllerMethods
    extend ActiveSupport::Concern

    included do
      include SortingMethods
    end

    def index
      collection = records

      opts = {
        include: serializer_includes,
        meta: meta(collection)
      }
      opts = yield(opts, collection) if block_given?

      respond_with collection, **opts
    end

    def show
      authorize(record)

      opts = { include: serializer_includes }
      opts = yield(opts, record) if block_given?

      respond_with record, **opts
    end

    def create
      record = new_record
      if record.valid?
        authorize(record)
        record.save
      else
        skip_authorization
      end
      opts = { include: serializer_includes }
      opts = yield(opts, record) if block_given?

      respond_with record, **opts
    end

    def update
      record.assign_attributes(permitted_attributes(record))
      if record.valid?
        authorize(record)
        record.save
      else
        skip_authorization
      end
      opts = { include: serializer_includes, json: record }
      opts = yield(opts, record) if block_given?

      respond_with record, **opts
    end

    def destroy
      authorize(record)
      record.destroy

      opts = {}
      opts = yield(opts, record) if block_given?

      respond_with record, **opts
    end

    def update_all
      ActiveRecord::Base.transaction do
        records(bulk: true).each do |record|
          # WARNING: Rails bug can prevent record associations from
          # updating after assigning foreign key. Make sure not to feed
          # records from an association, e.g. user.notifications
          # https://github.com/rails/rails/issues/24214
          attrs = permitted_attributes(record, :update)
          unless attrs.empty?
            record.assign_attributes(attrs)
            authorize(record, :update?)
            record.save
          end
        end
      end

      head :no_content
    end

    def destroy_all
      ActiveRecord::Base.transaction do
        records(bulk: true).each do |record|
          authorize(record, :destroy?)
          record.destroy
        end
      end

      head :no_content
    end

    private

    def new_record
      record_factory.new(permitted_attributes(record_factory))
    end

    def record
      @record ||= record_factory.find(record_id)
    end

    def records(bulk: false)
      collection = record_factory.all
      collection = apply_filter(collection)
      collection = apply_sorting(collection) if !bulk
      collection = policy_scope(collection)
      collection = apply_paging(collection) if !bulk
      collection = apply_includes(collection,
                                  bulk ? auth_includes : includes)
      collection
    end

    def record_factory
      fail NotImplementedError
    end

    def filter_factory
      (record_factory.to_s + 'Filter').constantize
    end

    def query_factory
      (record_factory.to_s + 'Query').constantize
    end

    def includes
      Utils.include_string_to_hash(serializer_includes)
    end

    def serializer_includes
      []
    end

    def auth_includes
      []
    end

    def record_id
      params.require(:id)
    end

    def sort_key_map
      {}
    end

    def allowed_sort_keys
      fail NotImplementedError
    end

    def query
      query_factory.new(filter_params)
    end

    def apply_includes(scope, _includes=includes)
      scope.includes(_includes)
    end

    def apply_filter(scope = nil)
      args = { query: query }
      args[:initial_scope] = scope if scope

      if block_given?
        yield(args)
      else
        filter_factory.new(**args).scope
      end
    end

    def filter_params
      if filter = params[:filter]
        filter.permit!
      else
        {}
      end
    end

    def apply_paging(scope)
      scope.page(page).per(per)
    end

    def per
      params[:per]
    end

    def page
      params[:page]
    end

    def meta(collection)
      { pagination: pagination_meta(collection) }
    end

    def pagination_meta(object)
      {
        current_page: object.current_page,
        next_page: object.next_page,
        prev_page: object.prev_page,
        total_pages: object.total_pages,
        total_count: object.total_count
      }
    end
  end
end
