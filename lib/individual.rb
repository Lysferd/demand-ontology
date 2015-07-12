# Encoding: UTF-8

#==============================================================================
# ** AbstractIndividual Class
#---------------------
#  Abstraction class for handling individuals from ontologies.
#==============================================================================

class AbstractIndividual < Dataset

  require 'time'

  attr_reader :name,
              :full_name,
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
    #@full_name         = individual.uri.match(/#([\w\+áéíóúàâêôãõç]+)$/i)[1]
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
  def parent
    return nil unless has_parent?
    return individual value :Pertence_A
  end

  #-------------------------------------------------------------------------
  def has_children?
    return !children.empty?
  end
  alias :is_parent?   :has_children?
  alias :has_children :has_children?
  alias :is_parent    :has_children?

  #-------------------------------------------------------------------------
  def has_parent?
    return has_property? :Pertence_A
  end

  #-------------------------------------------------------------------------
  def property property_name
    return model.get_property irify property_name.to_s
  end

  #-------------------------------------------------------------------------
  def properties
    return @individual.list_properties.reject { |property| property.to_s =~ /type/ }
  end

  #-------------------------------------------------------------------------
  def has_property? *property_names
    for property in property_names do
      return false unless @individual.has_property? model.get_property irify property.to_s
    end
    return true
  end

  #-------------------------------------------------------------------------
  def value property_name
    property = @individual.get_property_value property property_name
    return property.respond_to?(:value) ? property.value : property.as_individual
  end

  #-------------------------------------------------------------------------
  def apparent_power
    return 0 unless has_property? :Potência_Aparente
    return value :Potência_Aparente
  end

  #-------------------------------------------------------------------------
  def demand_factor
    return 1.0 unless has_property? :Fator_de_Demanda
    return value :Fator_de_Demanda
  end

  #-------------------------------------------------------------------------
  def power_factor
    return 1.0 unless has_property? :Fator_de_Potência
    return value :Fator_de_Potência
  end

  #-------------------------------------------------------------------------
  def usage_priority
    return nil unless has_property? :Prioridade_de_Uso
    return value :Prioridade_de_Uso
  end

  #-------------------------------------------------------------------------
  def generation_priority
    return nil unless has_property? :Prioridade_de_Geração
    return value :Prioridade_de_Geração
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
    return Math::sqrt(apparent_power.abs2 - active_power.abs2).round 3
  end

  #-------------------------------------------------------------------------
  def rdp
    return (demand.abs / priority).round 3
  end

  #-------------------------------------------------------------------------
  def start_time
    return '00:00' unless has_property? :Início_de_Atividade
    return value :Início_de_Atividade
  end

  #-------------------------------------------------------------------------
  def start_minute
    hour, minute = *start_time.match(/(\d+):(\d+)/).captures
    return hour.to_i * 60 + minute.to_i
  end

  #-------------------------------------------------------------------------
  def duration_time
    return '23:59' unless has_property? :Duração_de_Atividade
    return value :Duração_de_Atividade
  end

  #-------------------------------------------------------------------------
  def duration_minute
    hour, minute = *duration_time.match(/(\d+):(\d+)/).captures
    return hour.to_i * 60 + minute.to_i
  end

  #-------------------------------------------------------------------------
  def stop_time
    minutes = start_minute + duration_minute
    hour, minute = minutes / 60, minutes % 60
    hour -= 24 until hour < 24

    return '%02d:%02d' % [ hour, minute ]
  end

  #-------------------------------------------------------------------------
  def stop_minute
    hour, minute = *stop_time.match(/(\d+):(\d+)/).captures
    return hour.to_i * 60 + minute.to_i
  end

  #-------------------------------------------------------------------------
  def timeline property
    if has_children?
      timelines = [ ]

      for child in children do
        timelines += child.timeline property
      end

      return timelines
    else
      data = { }

      Range::new(0, 24 * 60).step( 15 ) do |minute|
        if minute < start_minute or minute >= stop_minute
          data[Time::new Time::new.year, Time::new.month, Time::new.day, minute / 60, minute % 60] = 0
        else
          data[Time::new Time::new.year, Time::new.month, Time::new.day, minute / 60, minute % 60] = self.send property
        end
      end

      return [ name: @name, data: data ]
    end
  end


  #-------------------------------------------------------------------------
  def activity_period
    return '%s até %02d:%02d' % [ start_time, stop_time[0..1], stop_time[3..4] ]
  end

  #-------------------------------------------------------------------------
  def summation property
    super children.map { |e| [ e, e.children ] }.flatten, property
  end

end