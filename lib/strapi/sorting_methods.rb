module Strapi
  module SortingMethods
    def apply_sorting(initial_scope)
      Sorting.new(initial_scope: initial_scope,
                  order_params: sort_params,
                  allowed_sort_keys: allowed_sort_keys,
                  sort_key_map: sort_key_map).scope
    end

    def sort_params
      params.fetch(:sort, '')
    end
  end
end
