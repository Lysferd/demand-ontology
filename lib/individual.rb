# Encoding: UTF-8

#==============================================================================
# ** AbstractIndividual Class
#---------------------
#  Abstraction class for handling individuals from ontologies.
#==============================================================================

class AbstractIndividual < Dataset

  attr_reader :name,
              :namespace,
              :iri,
              :ontological_class

  #-------------------------------------------------------------------------
  # * Object Initialization Method.
  #-------------------------------------------------------------------------
  def initialize individual
    @individual        = individual
    @name              = individual.local_name
    @namespace         = individual.name_space
    @iri               = individual.uri
    @ontological_class = individual.list_ont_classes(true).reject { |c| c.to_s =~ /NamedIndividual/ }[0]
  end

  #-------------------------------------------------------------------------
  def model
    return @individual.model
  end

  #-------------------------------------------------------------------------
  def kind_of? object
    return @ontological_class == object
  end
  alias :instance_of? :kind_of?
  alias :is_a?        :kind_of?

  #-------------------------------------------------------------------------
  def children
    return individuals parent: @individual
  end

  #-------------------------------------------------------------------------
  def has_children?
    return children.empty?
  end
  alias :is_parent?   :has_children?
  alias :has_children :has_children?
  alias :is_parent    :has_children?

  #-------------------------------------------------------------------------
  def properties
    return @individual.list_properties.reject { |property| property.to_s =~ /type/ }
  end

  #-------------------------------------------------------------------------
  def apparent_power
    return @individual.get_property(model.get_property(irify('Potência_Aparente'))).int rescue 0
  end

  #-------------------------------------------------------------------------
  def demand_factor
    return @individual.get_property(model.get_property(irify('Fator_de_Demanda'))).double rescue 1.0
  end

  #-------------------------------------------------------------------------
  def power_factor
    return @individual.get_property(model.get_property(irify('Fator_de_Potência'))).double rescue 1.0
  end

  #-------------------------------------------------------------------------
  def usage_priority
    return @individual.get_property(model.get_property(irify('Prioridade_de_Uso'))).int rescue nil
  end

  #-------------------------------------------------------------------------
  def generation_priority
    return @individual.get_property(model.get_property(irify('Prioridade_de_Geração'))).int rescue nil
  end

  #-------------------------------------------------------------------------
  def priority
    return usage_priority || generation_priority || 1
  end

  #-------------------------------------------------------------------------
  def demand
    return apparent_power * demand_factor
  end

  #-------------------------------------------------------------------------
  def active_power
    return apparent_power * power_factor
  end

  #-------------------------------------------------------------------------
  def reactive_power
    return Math::sqrt(apparent_power ** 2 - active_power ** 2).round 3
  end

  #-------------------------------------------------------------------------
  def rdp
    return (demand / priority).round 3
  end

  #-------------------------------------------------------------------------
  def summation property
    super children.map { |e| [ e, e.children ] }.flatten, property
  end

end