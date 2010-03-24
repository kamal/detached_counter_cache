module ActiveRecordExtensions
  module DetachedCounterCache
    module Base
      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:class_inheritable_accessor, :detached_counter_cache_table_names)
        class <<base
          alias_method_chain :update_counters, :detached_counters
          alias_method_chain :belongs_to, :detached_counters
        end
      end
      
      module ClassMethods
        def belongs_to_with_detached_counters(association_id, options = {})
          add_detached_counter_cache = options.delete(:detached_counter_cache)
          if add_detached_counter_cache
            placeholder = DetachedCounterCachePlaceholder.new
            options[:counter_cache] = placeholder
          end
          
          belongs_to_without_detached_counters(association_id, options)
          
          if add_detached_counter_cache
            reflection = reflections[association_id]
            placeholder.reflection = reflection
            reflection.klass.detached_counter_cache_table_names ||= []
            reflection.klass.detached_counter_cache_table_names.push(placeholder.detached_counter_table_name)
          end
        end
        
        def update_counters_with_detached_counters(id, counters)
          detached_counters = {}
          counters.each do |column_name, value|
            if column_name.is_a?(DetachedCounterCachePlaceholder)
              detached_counters[column_name] = value
              counters.delete(column_name)
            end
          end
          
          detached_counters.each do |placeholder, value|
            self.connection.execute(<<-SQL
              INSERT INTO `#{placeholder.detached_counter_table_name}` (user_id, count) VALUES (#{id}, #{value})
              ON DUPLICATE KEY UPDATE count = count + #{value}
            SQL
            )
          end
          
          update_counters_without_detached_counters(id, counters) unless counters.blank?
        end
      end
    end
    
    module HasManyAssociation
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.alias_method_chain :count_records, :detached_counters
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