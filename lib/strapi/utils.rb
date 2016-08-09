module Strapi
  class Utils
    def self.include_string_to_hash(included)
      included.inject({}) do |hash, path|
        hash.deep_merge!(
          path.split('.').reverse_each.inject({}) { |a, e| { e.to_sym => a } }
        )
      end
    end
  end
end
