# encoding: UTF-8

# Smile - add methods to the Project model

# 1/ module FilterPossibleValues
# - #113099 Possibilité de cacher par défaut des valeurs de champ personnalisés
#   2014


#require 'active_support/concern' #Rails 3

module Smile
  module Models
    module ProjectOverride
      #************************
      # 1/ FilterPossibleValues
      module FilterPossibleValues
        # extend ActiveSupport::Concern

        def self.prepended(base)
          filter_possible_values_instance_methods = [
            :ancestors_identifiers, # 1/ new method V4.0.0 OK
          ]

          trace_prefix       = "#{' ' * (base.name.length + 27)}  --->  "
          last_postfix       = '< (SM::MO::ProjectOverride::FilterPossibleValues)'

          smile_instance_methods = base.instance_methods.select{|m|
              base.instance_method(m).owner == self
            }

          missing_instance_methods = filter_possible_values_instance_methods.select{|m|
            !smile_instance_methods.include?(m)
          }

          if missing_instance_methods.any?
            trace_first_prefix = "#{base.name} MISS          instance_methods  "
          else
            trace_first_prefix = "#{base.name}               instance_methods  "
          end

          SmileTools::trace_by_line(
            (
              missing_instance_methods.any? ?
              missing_instance_methods :
              smile_instance_methods
            ),
            trace_first_prefix,
            trace_prefix,
            last_postfix,
            :redmine_smile_list_cf_possible_values_filter
          )

          if missing_instance_methods.any?
            raise trace_first_prefix + missing_instance_methods.join(', ') + '  ' + last_postfix
          end
        end # def self.prepended

        # 1/ new method, RM 4.0.0 OK
        # Cached, eager loaded
        # Smile specific #113099 Possibilité de cacher par défaut des valeurs de champ personnalisés
        def ancestors_identifiers
          return @ancestors_identifiers if defined?(@ancestors_identifiers)

          @ancestors_identifiers = ancestors.pluck(:identifier)
        end
      end # module FilterPossibleValues
    end # module ProjectOverride
  end # module Models
end # module Smile
