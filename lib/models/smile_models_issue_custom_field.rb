# Smile - add methods to the IssueCustomField model
#
# 1/ module FilterPossibleValues
#     #113099 Champ Perso. de type liste : Possibilité de cacher par défaut des valeurs possibles
#       Makes hidden_values accept a multiline string
#       Add hidden values
#       Makes hidden_values_projects_exclusions accept a multiline string
#       Filter possible values by project


#require 'active_support/concern' #Rails 3

module Smile
  module Models
    module IssueCustomFieldOverride
      module FilterPossibleValues
        # extend ActiveSupport::Concern

        def self.prepended(base)
          filter_possible_values_instance_methods = [
            :hidden_values=,                     # 1/ OVERRIDEN ORM new  RM 4.0.0 OK
            :hidden_values_projects_exclusions=, # 2/ OVERRIDEN ORM new  RM 4.0.0 OK
            :possible_values,                    # 3/ OVERRIDEN extemded RM 4.0.0 OK
            :hidden_values,                      # 4/ OVERRIDEN ORM new  RM 4.0.0 OK
            :hidden_values_projects_exclusions,  # 5/ OVERRIDEN ORM new  RM 4.0.0 OK
          ]


          trace_prefix       = "#{' ' * (base.name.length + 15)}   --->  "
          last_postfix       = '< (SM::MO::IssueCustomFieldOverride::FilterPossibleValues)'

          smile_instance_methods = base.instance_methods.select{|m|
              base.instance_method(m).owner == self
            }

          missing_instance_methods = filter_possible_values_instance_methods.select{|m|
            !smile_instance_methods.include?(m)
          }

          if missing_instance_methods.any?
            trace_first_prefix = "#{base.name} MISS instance_methods  "
          else
            trace_first_prefix = "#{base.name}      instance_methods  "
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
        end # def self.prepended(base)


        # 1/ dynamic ORM field OVERRIDEN, field added by plugin RM 4.0.0 OK
        # Smile specific : Makes hidden_values accept a multiline string
        def hidden_values=(arg)
          if arg.is_a?(Array)
            super( arg.join("\n\r") )
          else
            super( arg )
          end
        end

        # 2/ dynamic ORM field OVERRIDEN, field added by plugin RM 4.0.0 OK
        # Smile specific : Makes hidden_values_projects_exclusions accept a multiline string
        def hidden_values_projects_exclusions=(arg)
          if arg.is_a?(Array)
            super( arg.join("\n\r") )
          else
            super( arg )
          end
        end

        # 3/ CustomField.possible_values OVERRIDEN extended, RM 4.0.0 OK
        # Smile specific : cache added
        # Smile specific : caches also possible_values_unfiltered
        def possible_values
          return @possible_values if defined?(@possible_values)

          @possible_values_unfiltered = super

          @possible_values = @possible_values_unfiltered.dup
        end

        # 4/ dynamic ORM field OVERRIDEN extended, field added by plugin RM 4.0.0 OK
        # Smile specific : cache added
        # Smile specific : manage multiline string
        def hidden_values
          return @hidden_values if defined?(@hidden_values)

          @hidden_values = super
          if @hidden_values
            @hidden_values = @hidden_values.split(/[\n\r]+/)
          else
            @hidden_values = []
          end

          @hidden_values
        end

        # 5/ dynamic ORM field OVERRIDEN extended, field added by plugin RM 4.0.0 OK
        # Smile specific : cache added
        # Smile specific : manage multiline string
        def hidden_values_projects_exclusions
          return @hidden_values_projects_exclusions if defined?(@hidden_values_projects_exclusions)

          @hidden_values_projects_exclusions = super
          if @hidden_values_projects_exclusions
            @hidden_values_projects_exclusions = @hidden_values_projects_exclusions.split(/[\n\r]+/)
          else
            @hidden_values_projects_exclusions = []
          end

          @hidden_values_projects_exclusions
        end
      end # module FilterPossibleValues
    end # module IssueCustomFieldOverride
  end # module Models
end # module Smile
