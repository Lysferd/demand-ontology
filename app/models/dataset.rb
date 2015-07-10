# Encoding: UTF-8

class Dataset < ActiveRecord::Base

  #-=-=-=-=-=-=-
  # Jena-JRuby Library
  require 'jena_jruby'
  require 'fileutils'
  require 'individual'

  #-=-=-=-=-=-=-
  # Module Mixins
  #include ActiveModel::Dirty
  include Jena
  include Core, TDB, Query, Ont, Reasoner

  #-=-=-=-=-=-=-
  # Constants
  DATASET_FOLDER = File::join( Dir::pwd, 'datasets' )

  SPARQL_TEMPLATES = [
      {
          description: 'Apresentar todas as classes:',
          query: 'SELECT ?class WHERE { ?class a owl:Class }'
      },

      {
          description: 'Apresentar todos os indivíduos pertencentes à classe determinada (substituir [myclass] pelo nome da classe):',
          query: 'SELECT ?individual WHERE { ?individual rdf:type demand:[myclass] }'
      },

      {
          description: 'Apresentar propriedades distintas de um indivíduo de uma classe (substituir [myclass] pelo nome da classe):',
          query: 'SELECT DISTINCT ?o ?p ?v WHERE { ?o a demand:[myclass] . ?o ?p ?v . }'
      },

      {
          description: 'Soma das potências de todos os Alimentadores:',
          query: 'SELECT (SUM(?value) AS ?summedval) WHERE { ?object ?property ?value . ?object a demand:Alimentador . ?object demand:Potência_Aparente ?value . }'
      }
  ]

  #-=-=-=-=-=-=-
  # Callbacks
  before_create :create_dataset
  before_update :update_dataset
  before_destroy :destroy_tdb

  #-=-=-=-=-=-=-
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :rdf_source, presence: true

  #-=-=-=-=-=-=-
  # Table References
  belongs_to :user

  private
  #-------------------------------------------------------------------------
  # * Dataset TDB Files Creation
  #  This method creates the directory tree, RDF/OWL model and TDB files.
  #-------------------------------------------------------------------------
  def create_dataset
    fix_name( self.name )

    # -=-=-=-=-
    # Make directories as needed.
    path = File::join( DATASET_FOLDER, self.name )
    FileUtils::mkdir_p path unless FileTest::exist? path

    model_filename = fix_name( self.rdf_source[0].original_filename )
    upload_model( File::join(path, model_filename), self.rdf_source[0] )
    self.rdf_source = model_filename

    # -=-=-=-=-
    # Populate Dataset with the Ontology Model.
    datawrite do
      tdb.get_default_model.add rdf_model
      tdb.commit
    end

  end

  #-------------------------------------------------------------------------
  # * Dataset TDB Files Update
  #  This method updates the Dataset data, and merges any additional models
  # uploaded from the view.
  #-------------------------------------------------------------------------
  def update_dataset
    if self.name_changed?
      fix_name( self.name )
      old_path = File::join( DATASET_FOLDER, self.changed_attributes[:name] )
      new_path = File::join( DATASET_FOLDER, self.name )
      FileUtils::mv( old_path, new_path )
    end

    # -=-=-=-=-
    # Generate union model from existing model and new model.
    if self.rdf_source_changed?
      # do not create instance variable @rdf_model
      base_model = ModelFactory::create_ontology_model( OntModelSpec::OWL_MEM )
      original_path = File::join( DATASET_FOLDER, self.name, self.changed_attributes[:rdf_source] )
      Util::FileManager::get.read_model( base_model, original_path )

      # The new model
      model_filename = self.rdf_source[0].original_filename.gsub( ?\s, ?_ )
      new_path = File::join( DATASET_FOLDER, self.name, model_filename )
      upload_model( new_path, self.rdf_source[0] )
      new_model = ModelFactory::create_ontology_model( OntModelSpec::OWL_MEM )
      Util::FileManager::get.read_model( new_model, new_path )
      File::delete( new_path )

      # Union model
      union_model = ModelFactory::create_union( base_model, new_model )
      out = java.io.FileOutputStream::new( original_path )
      union_model.write( out )
      out.close

      # Only the model's contents change, so back to original name
      self.rdf_source = self.changed_attributes[:rdf_source]

      # Populate Dataset with the Ontology Model.
      datawrite do
        tdb.get_default_model.add rdf_model
        tdb.commit
      end
    end
  end

  #-------------------------------------------------------------------------
  def upload_model path, data
    File::open( path, 'wb' ) { |rdf| rdf.write data.read }
  end

  #-------------------------------------------------------------------------
  def dataset_path
    return File::join DATASET_FOLDER, self.name, self.rdf_source
  end

  #-------------------------------------------------------------------------
  def tdb_path
    return File::join DATASET_FOLDER, self.name, 'tdb'
  end

  #-------------------------------------------------------------------------
  # * IRI Name Fix
  #  Replaces all space characters ' ' for underscore characters '_' in
  # order to avoid inconsistent IRIs.
  #
  # @param [String] name_string
  #-------------------------------------------------------------------------
  def fix_name( name_string )
    return name_string.gsub ?\s, ?_
  end

  #-------------------------------------------------------------------------
  # * IRI Value Generation
  #  Helper method that generates a valid IRI value.
  # Inside ontologies, individuals, classes and properties cannot have name
  # values with space characters ' ', for they are displayed in the URI, and
  # URIs cannot have spaces. Instead, spaces should be replaced by underscore
  # characters '_'.
  #-------------------------------------------------------------------------
  def irify( name )
    name = fix_name name
    return name if name =~ /#{namespace}/
    return namespace + name
  end

  #-------------------------------------------------------------------------
  # * Get Ontology Namespace
  #  This method returns the ontology's namespace from the RDF/OWL source,
  # since as of version 2.12.0 of Jena, there is a bug that impedes the
  # dataset model from storing prefix values.
  #-------------------------------------------------------------------------
  def namespace
    return rdf_model.ns_prefix_map['']
  end

  #-------------------------------------------------------------------------
  # * Get OWL Prefix
  #-------------------------------------------------------------------------
  def owl_prefix
    return rdf_model.ns_prefix_map['owl']
  end

  #-------------------------------------------------------------------------
  def query_prefixes
    model.ns_prefix_map.map { |key, value| "PREFIX #{key.empty? ? ':' : key}: <#{value}>" }.join ?\n
  end

  #-------------------------------------------------------------------------
  # * Create RDF/OWL Source Model
  #-------------------------------------------------------------------------
  def load_rdf_model
    rdf_model = ModelFactory::create_ontology_model OntModelSpec::OWL_MEM
    Util::FileManager::get.read_model rdf_model, dataset_path

    return rdf_model
  end

  #-------------------------------------------------------------------------
  # * Get RDF/OWL Source Model
  #-------------------------------------------------------------------------
  def rdf_model
    return @rdf_model ||= load_rdf_model
  end

  #-------------------------------------------------------------------------
  # * Create Dataset Model
  #  This method loads and returns the model inside the TDB.
  # Note that #default_model returns an instance of `ModelCom' class,
  # which does not provide the ever-so-helpful methods like #list_individuals
  # nor #list_classes. In order to be able to use these methods without SPARQL
  # queries, it is necessary that a new `OntModel' object to be created, based
  # on the default model within the dataset.
  #
  #  This method has been enhanced to check if the TDB is already in a
  # transaction, and if true, does not tries to overlap it with yet another
  # transaction. This fixes the following error:
  # 'Java::ComHpHplJenaTdb::TDBException: Read-only block manager`
  #-------------------------------------------------------------------------
  def load_tdb_model
    base_model = tdb.in_transaction ? tdb.default_model : dataread { tdb.default_model }
    model = ModelFactory::create_ontology_model OntModelSpec::OWL_MEM, base_model
    model.set_strict_mode false

    return model
  end

  #-------------------------------------------------------------------------
  # * Get Dataset Model
  #-------------------------------------------------------------------------
  def model
    return @model ||= load_tdb_model
  end

  #-------------------------------------------------------------------------
  # * Get/Create TDB
  #-------------------------------------------------------------------------
  def tdb
    return( @tdb ||= TDBFactory::create_dataset tdb_path )
  end

  #-------------------------------------------------------------------------
  # * Destroy TDB
  #-------------------------------------------------------------------------
  def destroy_tdb
    FileUtils::rm_r( File::join( DATASET_FOLDER, self.name ) )
  end

  #-------------------------------------------------------------------------
  # * Start TDB Transaction
  #  A helper method to ease the use of TDB transactions.
  #
  # Arguments:
  #  kind (Symbol) - :read, :write
  #
  # Note that if the TDB is already undergoing a transaction, the Jena API will
  # raise a Java::ComHpHplJenaSparql::JenaTransactionException exception, which
  # is not rescue'd by design, since this is the most effective way to evade
  # developing glitchy code with overlapping transactions.
  #
  # Also note that write transactions shall not automatically commit changes,
  # so that the developer can decide to commit or rollback changes in runtime.
  #-------------------------------------------------------------------------
  def transaction( kind )
    case kind
    when :read
      tdb.begin ReadWrite::READ
    when :write
      tdb.begin ReadWrite::WRITE
    else
      fail ArgumentError, 'Expected valid transaction type: read or write.'
    end

    yield
  ensure
    tdb.end if tdb.in_transaction?
  end

  #-------------------------------------------------------------------------
  # * Start TDB Read Transaction
  #  Helper method that simply passes the given block to the real transaction
  # method.
  #-------------------------------------------------------------------------
  def dataread
    transaction :read, &Proc::new
  end

  #-------------------------------------------------------------------------
  # * Start TDB Write Transaction
  #  Helper method that simply passes the given block to the real transaction
  # method.
  #-------------------------------------------------------------------------
  def datawrite
    transaction :write, &Proc::new
  end

  public
  #-------------------------------------------------------------------------
  # * Dataset Individual Creation
  #-------------------------------------------------------------------------
  def create_individual args
    datawrite do

      # -=-=-=-=-
      ont_class_iri = irify args[:class]
      ont_class = model.get_ont_class( ont_class_iri )

      unless ont_class
        fail ArgumentError, 'Given ontology class does not exist.'
        tdb.abort
      end

      # -=-=-=-=-
      individual_iri = irify args[:name]
      individual = model.create_individual( individual_iri, ont_class )

      # -=-=-=-=-
      # Manually include individual in owl:NamedIndividual type.
      named_individual = model.create_class( owl_prefix + 'NamedIndividual' )
      model.create_individual( individual_iri, named_individual )

      for key, value in args[:property] do
        property_iri = irify( key.split( ?: )[1] )
        property = model.get_property( property_iri )

        if key =~ /resource/
          resource_iri = irify( value )
          resource = model.get_individual( resource_iri )
        else
          resource = case key
                       when /int/     then model.create_typed_literal( value.to_i )
                       when /double/  then model.create_typed_literal( value.to_f )
                       when /literal/ then model.create_typed_literal( value.to_s )
                       else model.create_literal( value )
                     end
        end

        individual.add_property( property, resource )
      end if args[:property]

      tdb.commit

      return individual
    end
  end

  #-------------------------------------------------------------------------
  def update_individual args
    datawrite do
      individual = model.get_individual( irify( args[:original_name] ) )

      unless args[:original_name] == args[:name]
        Util::ResourceUtils::rename_resource( individual, irify( args[:name] ) )
        individual = model.get_individual( irify( args[:name] ) )
      end

      # FIXME: sometimes the owl:NamedIndividual class gets in the way.
      ont_class = model.get_ont_class( namespace + args[:class] )
      individual.ont_class = ont_class unless individual.get_ont_class == ont_class

      for key, value in args[:property] do
        property = model.get_property(namespace + key.split(':')[1])

        if key =~ /destroy/
          resource = individual.get_property_value( property )
          individual.remove_property( property, resource )

        else
          resource = case key
                     when /int/     then ResourceFactory::create_typed_literal( value.to_i )
                     when /double/  then ResourceFactory::create_typed_literal( value.to_f )
                     when /literal/ then ResourceFactory::create_typed_literal( value.to_s )
                     else model.get_individual( irify( value ) )
                     end

          if individual.has_property?(property) and not individual.get_property_value( property ) == resource
            individual.set_property_value(property, resource)
          else
            individual.add_property(property, resource)
          end
        end
      end if args[:property]

      tdb.commit

      return true
    end
  end

  #-------------------------------------------------------------------------
  def destroy_individual name
    datawrite do
      individual = model.get_individual irify name
      if not individual
        tdb.abort
        fail ArgumentError, 'Given individual does not exist.'
      else
        individual.remove
        tdb.commit
      end
    end
  end

  #-------------------------------------------------------------------------
  # * Individual Abstraction Method
  #  This method abstracts a single individual from the ontology, given a valid
  # individual name (local_name, full URI, or Individual).
  #
  # @param [String] object
  #-------------------------------------------------------------------------
  def individual object
    return AbstractIndividual::new object.kind_of?(Individual) ? object : model.get_individual(irify(object))
  end

  #-------------------------------------------------------------------------
  def ontology_class name
    return model.get_ont_class irify name
  end

  #-------------------------------------------------------------------------
  # * Abstraction of Multiple Individuals Method
  #  This method collects and returns abstraction individuals out of all
  # individuals that match a given filter.
  #
  # @param [Hash] filter
  #-------------------------------------------------------------------------
  def individuals filter = Hash[]
    return case

    # -=-=-=-=-=-
    # Select individuals that match a certain ontological class.
    when filter[:class]
      ontological_class = filter[:class].kind_of?(String) ? ontology_class( filter[:class] ) : filter[:class]
      model.list_individuals.select { |i| i.has_ont_class? ontological_class }

    # -=-=-=-=-=-
    # Select individuals that match a certain parent.
    when filter[:parent]
      parent = filter[:parent].kind_of?(String) ? individual(filter[:parent]) : filter[:parent]
      property = model.get_object_property irify 'Pertence_A'

      model.list_individuals.select do |i|
        i.has_property? property and i.get_property_value( property ) == parent
      end

    # -=-=-=-=-=-
    # Select all individuals.
    else
      model.list_individuals

    end.map { |i| logger.debug i; individual i }
  end

  #-------------------------------------------------------------------------
  # * Get All Feeders
  #  Helper method to easily get all individuals with class `Alimentador'.
  #-------------------------------------------------------------------------
  def feeders
    return individuals class: 'Alimentador'
  end

  #-------------------------------------------------------------------------
  # * Get All Building Systems
  #  Helper method to easily get all individuals with class
  # `Sistema_Predial'.
  #-------------------------------------------------------------------------
  def building_systems
    return individuals class: 'Sistema_Predial'
  end

  #-------------------------------------------------------------------------
  # * Individual Property Summation
  #  Sums `property' of all individuals in the Array.
  #
  # @param [Array] individuals
  # @param [Symbol] property
  #-------------------------------------------------------------------------
  def summation individuals, property
    return individuals.map( &property ).inject( &:+ ).round 3
  end

  #-------------------------------------------------------------------------
  # * Dataset Triple Count
  #-------------------------------------------------------------------------
  def count
    return model.size
  end

  #-------------------------------------------------------------------------
  # * Model Triple Count
  #-------------------------------------------------------------------------
  def count_rdf
    return rdf_model.size
  end

  #-------------------------------------------------------------------------
  # * Dataset Classes
  #  Returns an instance of `Array' containing all the classes from the model,
  # properly removing the trailing namespace.
  #-------------------------------------------------------------------------
  def classes
    model.list_classes.to_a
  end

  #-------------------------------------------------------------------------
  # * Dataset Properties
  #  Returns an instance of `Array' containing all the Object and Data(type)
  # properties from the model.
  #-------------------------------------------------------------------------
  def properties
    object_properties + datatype_properties
  end

  #-------------------------------------------------------------------------
  # * Dataset Object Properties
  #-------------------------------------------------------------------------
  def object_properties
    model.list_object_properties.to_a
  end

  #-------------------------------------------------------------------------
  # * Dataset Data(type) Properties
  #-------------------------------------------------------------------------
  def datatype_properties
    model.list_datatype_properties.to_a
  end

  #-------------------------------------------------------------------------
  # * Reasoner Inferences
  #-------------------------------------------------------------------------
  def reason resource_name
    schema = ModelFactory::create_default_model
    schema.read owl_prefix

    reasoner = ReasonerRegistry::get_owl_reasoner
    reasoner.bind_schema schema

    infmodel = ModelFactory::create_inf_model reasoner, model
    resource = infmodel.get_resource irify resource_name

    return infmodel.list_statements resource, nil, nil
  end

  #-------------------------------------------------------------------------
  # * Dataset Query
  #-------------------------------------------------------------------------
  def query string
    dataread do
      query = QueryFactory::create query_prefixes + string
      yield QueryExecutionFactory::create query, model
    end
  end

  #-------------------------------------------------------------------------
  # * Array of Query Results
  #  This helper method populates an `Array' object with the results of the
  # query.
  #-------------------------------------------------------------------------
  def query_to_array string
    results = [ ]

    query string do | execution |
      execution.exec_select.each do | result |
        results << result
      end
    end

    return results
  rescue Java::ComHpHplJenaQuery::QueryParseException
    return [ $!.message ]
  end
end
