module DatasetHelper

  def select_helper( classes, *args )
    options_for_select(
        classes.collect { |c| [c.local_name.gsub(/_/, ' ').titleize, c.local_name] },
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
      [prop.local_name.gsub(/_/, ' ').titleize, type + prop.local_name]
    end

    options_for_select options
  end

  def ont_class( individual )
    individual.list_ont_classes( true ).map do | m |
      return m.local_name.gsub( /_/, ' ' ).titleize unless m.local_name =~ /NamedIndividual/
    end
  rescue
    return $!.message
  end

end
