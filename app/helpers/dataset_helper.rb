module DatasetHelper

  def select_helper( classes, *args )
    options_for_select(
        classes.collect do |c|
          name = c.respond_to?(:name) ? c.name : c.local_name
          [name, name]
        end,
      *args
    )
  end

  def select_properties(properties)
    options = properties.collect do |prop|
      if prop.object_property?
        type = 'resource:'
      elsif prop.datatype_property?
        type = prop.get_range.local_name.downcase + ':'
      end
      [prop.local_name, type + prop.local_name]
    end

    options_for_select options
  end

end
