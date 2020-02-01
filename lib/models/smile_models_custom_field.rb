# Smile - add methods to the CustomField model
#
# 1/ module FilterPossibleValues
#    - #113099 Champ Perso. de type liste : Possibilité de cacher pas défaut des valeurs possibles
#      Keep a way to get possible values unfiltered


#require 'active_support/concern' #Rails 3

module Smile
  module Models
    module CustomFieldOverride
      module FilterPossibleValues
        # extend ActiveSupport::Concern

        def self.prepended(base)
          filter_possible_values_instance_methods = [
            :possible_values_unfiltered,             # 1/ new method RM V4.0.0 OK
          ]

          if defined?(Localizable)
            filter_possible_values_instance_methods += [
              :possible_values_localized_unfiltered, # 2/ new method RM V4.0.0 OK
              :localize_value_if_list_type,          # 3/ REWRITTEN  RM V4.0.0 OK
            ]
          end

          trace_prefix       = "#{' ' * (base.name.length + 21)}  --->  "
          last_postfix       = '< (SM::MO::CustomFieldOverride::FilterPossibleValues)'

          smile_instance_methods = base.instance_methods.select{|m|
              base.instance_method(m).owner == self
            }

          missing_instance_methods = filter_possible_values_instance_methods.select{|m|
            !smile_instance_methods.include?(m)
          }

          if missing_instance_methods.any?
            trace_first_prefix = "#{base.name} MISS      instance_methods  "
          else
            trace_first_prefix = "#{base.name}           instance_methods  "
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


          safe_attributes_added = [
            :hidden_values,
            :hidden_values_projects_exclusions,
          ]

          if base.respond_to?(:safe_attributes)
            base.instance_eval do
              safe_attributes 'hidden_values', 'hidden_values_projects_exclusions', :if => lambda {|cf, user| cf.field_format == 'list'}
            end

            trace_first_prefix = "#{base.name}            safe_attributes  "
          else
            trace_first_prefix = "#{base.name} RM<3.4 NOT safe_attributes  "
          end

          SmileTools::trace_by_line(
            safe_attributes_added,
            trace_first_prefix,
            trace_prefix,
            last_postfix,
            :redmine_smile_list_cf_possible_values_filter
          )
        end

        # 1/ new method  RM V4.0.0 OK
        # cache values
        def possible_values_unfiltered
          # This call enables the cache if provided by plugin
          possible_values_uncached = possible_values
          if defined?(@possible_values_unfiltered)
            return @possible_values_unfiltered
          else
            return possible_values_uncached
          end
        end

        # Localizable plugin installed ?
        if defined?(Localizable)
          # 2/ new method  RM V4.0.0 OK
          def possible_values_localized_unfiltered
            return @possible_values_localized_unfiltered if defined?(@possible_values_localized_unfiltered)

            @possible_values_localized_unfiltered = get_possible_values_localized(possible_values_unfiltered)
          end

          # 3/ REWRITTEN  RM V4.0.0 OK
          # From Localizable plugin
          #
          # Localize a value of type list (with localized possible_values)
          def localize_value_if_list_type(p_value)
            return p_value unless to_localize_because_list_type?

            # Multiple values case
            if p_value.is_a?(Array)
              # Duplicated to not affect over uses of custom_values
              value_localized = []
              p_value.each{|v|
                # Recursive call
                value_localized << localize_value_if_list_type(v)
              }

              return value_localized
            end

            ####################
            # Specific to plugin : possible_values -> possible_values_unfiltered
            possible_values_unfiltered.each_with_index{ |pv, i|
              if p_value == pv
                # possible_values_localized is cached
                ####################
                # Specific to plugin : possible_values_localized -> possible_values_localized_unfiltered
                value_localized = possible_values_localized_unfiltered[i]

                # Value changed ?
                # If NOT return the original value
                if value_localized != p_value
                  # logger.debug "==>cf localize_value_if_list_type #{p_value} --> #{value_localized}"
                  p_value = value_localized
                end

                break
              end
            }

            p_value
          end # def localize_value_if_list_type(p_value)
        end # if respond_to?(:possible_values_localized)
      end # module FilterPossibleValues
    end # module CustomFieldOverride
  end # module Models
end # module Smile
