module Strapi
  class Sorting
    def initialize(initial_scope:,
                   order_params:'',
                   allowed_sort_keys: [],
                   sort_key_map: {})
      @initial_scope     = initial_scope
      @order_params      = order_params
      @allowed_sort_keys = allowed_sort_keys
      @sort_key_map    = sort_key_map
    end

    def scope
      order_args = build_order_args(
        order_params,
        allowed_sort_keys,
        sort_key_map
      )
      initial_scope.order(order_args)
    end

    private

    attr_reader :initial_scope, :order_params, :allowed_sort_keys, :sort_key_map

    def build_order_args(order_params, allowed_sort_keys, sort_key_map)
      transform_relationships(
        ordered_slice(
          order_params.split(',')
            .map { |x| [x.delete('-'), x.include?('-') ? 'DESC' : 'ASC'] }
            .to_h,
          allowed_sort_keys), sort_key_map)
    end

    def transform_relationships(orders, sort_key_map)
      orders.flat_map do |key, dir|
        Array(sort_key_map[key] || key)
          .map { |col| [col, dir] }
      end.map do |(key, dir)|
        key.include?('.') ? "#{key} #{dir}" : { key => dir }
      end
    end

    def ordered_slice(hash, keys)
      hash.keys
        .each_with_object({}) { |k, h|
          h[k] = hash[k] if keys.include?(k)
        }
    end
  end
end
