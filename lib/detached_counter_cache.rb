module ActiveRecordExtensions
  module DetachedCounterCache
    module Base
      extend ActiveSupport::Concern

      included do
        class_inheritable_accessor :detached_counter_cache_table_names
      end

      module ClassMethods
        def belongs_to(association_id, options = {})
          add_detached_counter_cache = options.delete(:detached_counter_cache)
          if add_detached_counter_cache
            placeholder = DetachedCounterCachePlaceholder.new
            options[:counter_cache] = placeholder
          end

          super

          if add_detached_counter_cache
            reflection = reflections[association_id]
            placeholder.reflection = reflection
            reflection.klass.detached_counter_cache_table_names ||= []
            reflection.klass.detached_counter_cache_table_names.push(placeholder.detached_counter_table_name)
          end
        end

        def update_counters(id, counters)
          detached_counters = {}
          counters.each do |column_name, value|
            if column_name.is_a?(DetachedCounterCachePlaceholder)
              detached_counters[column_name] = value
              counters.delete(column_name)
            end
          end

          detached_counters.each do |placeholder, value|
            self.connection.execute(<<-SQL
              INSERT INTO `#{placeholder.detached_counter_table_name}` (#{placeholder.reflection.primary_key_name}, count) VALUES (#{id}, #{value})
              ON DUPLICATE KEY UPDATE count = count + #{value}
            SQL
            )
          end

          super unless counters.blank?
        end
      end
    end

    module HasManyAssociation
      extend ActiveSupport::Concern

      included do
        alias_method_chain :count_records, :detached_counters
      end

      module InstanceMethods
        def count_records_with_detached_counters
          potential_table_name = [@owner.class.table_name, @reflection.klass.table_name, 'counts'].join('_')

          if (@owner.class.detached_counter_cache_table_names || []).include?(potential_table_name)
            row = connection.select_all("select count from `#{potential_table_name}` where #{@reflection.primary_key_name} = #{@owner.id}")[0]
            row.blank? ? 0 : row['count'].to_i
          else
            count_records_without_detached_counters
          end
        end
      end
    end

    class DetachedCounterCachePlaceholder
      attr_accessor :reflection

      def detached_counter_table_name
        [reflection.klass.table_name, reflection.active_record.table_name, 'counts'].join('_')
      end
    end
  end
end

ActiveRecord::Base.send( :include, ActiveRecordExtensions::DetachedCounterCache::Base )
ActiveRecord::Associations::HasManyAssociation.send( :include, ActiveRecordExtensions::DetachedCounterCache::HasManyAssociation )
