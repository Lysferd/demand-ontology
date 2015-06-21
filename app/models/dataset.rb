class Dataset < ActiveRecord::Base

  #-=-=-=-=-=-=-
  # Jena-JRuby Library
  require( 'jena_jruby' )

  #-=-=-=-=-=-=-
  # Module Mixins
  include Jena
  include Core, TDB, Query, Ont

  #-=-=-=-=-=-=-
  # Constants
  DATASET_FOLDER = File::join( Dir::pwd, 'datasets' )

  #-=-=-=-=-=-=-
  # Callbacks
  before_create :generate_tdb
  before_destroy :destroy_tdb

  #-=-=-=-=-=-=-
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :rdf_source, presence: true

  #-=-=-=-=-=-=-
  # Table References
  belongs_to :user

  private
  #============================================================================
  # *
  #============================================================================
  def generate_tdb
    self.name = self.name.downcase.split.join( '_' )

    # -=-=-=-=-
    # Create folder for all datasets.
    path = DATASET_FOLDER
    Dir::mkdir( path ) unless FileTest::exist?( path )

    # -=-=-=-=-
    # Create folder for this dataset.
    # fixme: name cannot contain spaces
    #   or they have to be escaped
    path += "/#{self.name}"
    Dir::mkdir( path ) unless FileTest::exist?( path )

    # -=-=-=-=-
    # Save uploaded RDF source file.
    path += "/#{self.rdf_source[0].original_filename.downcase.split.join( '_' )}"
    File::open( path, 'wb' ) do | rdf |
      rdf.write( self.rdf_source[0].read )
    end
    self.rdf_source = self.rdf_source[0].original_filename.downcase.split.join( '_' )

    # -=-=-=-=-
    # Populate Dataset with the Ontology Model.
    datawrite do
      tdb.get_default_model.add( rdf_model )
      tdb.commit
    end
  end

  public
  #============================================================================
  # * Get Ontology Namespace
  #  This method returns the ontology's namespace from the RDF/OWL source,
  # since as of version 2.12.0 of Jena, there is a bug that impedes the
  # dataset model from storing prefix values.
  #============================================================================
  def namespace
    return rdf_model.get_ns_prefix_map['']
  end

  #============================================================================
  # * Get OWL Prefix
  #============================================================================
  def owl_prefix
    return rdf_model.get_ns_prefix_map['owl']
  end

  #============================================================================
  # * Get/Create RDF/OWL Source Model
  #============================================================================
  def rdf_model
    unless @rdf_model
      @rdf_model = ModelFactory::create_ontology_model( OntModelSpec::OWL_MEM )
      Util::FileManager::get.read_model( @rdf_model, File::join( DATASET_FOLDER, self.name, self.rdf_source ) )
    end
    return @rdf_model
  end

  #============================================================================
  # * Get/Create Dataset Model
  #  This method loads and returns the model inside the TDB.
  # Note that #get_default_model returns an instance of `ModelCom' class,
  # which does not provide the ever-so-helpful methods like #list_individuals
  # nor #list_classes. In order to be able to use these methods without SPARQL
  # queries, it is necessary that a new `OntModel' object to be created, based
  # on the default model within the dataset.
  #
  #  This method has been enhaced to check if the TDB is already in a
  # transaction, and if true, does not tries to overlap it with yet another
  # transaction. This fixes the following error:
  # 'Java::ComHpHplJenaTdb::TDBException: Read-only block manager`
  #============================================================================
  def model
    unless @model
      spec = OntModelSpec::OWL_MEM
      if tdb.in_transaction?
        base_model = tdb.get_default_model
      else
        base_model = dataread { tdb.get_default_model }
      end
      @model = ModelFactory::create_ontology_model( spec, base_model )
    end
    return @model
  end

  #============================================================================
  # * Get/Create TDB
  #============================================================================
  def tdb
    unless @tdb
      path = File::join( DATASET_FOLDER, self.name, 'tdb' )
      @tdb = TDBFactory::create_dataset( path )
    end
    return @tdb
  end

  #============================================================================
  # * Destroy TDB
  # FIXME just destroying the files on disk does not destroys it from memory.
  # FIXME this method does not permanently remove the files, which accumulate
  #       in the system's recycle bin and waste resources.
  #============================================================================
  def destroy_tdb
    FileUtils::rm_r( File::join( DATASET_FOLDER, self.name ) )
  end

  #============================================================================
  # * Start TDB Transaction
  #  A helper method to ease the use of TDB transactions.
  #
  # Arguments:
  #  kind (Symbol) - :read, :r, :write, or :w
  #
  # Note that if the TDB is already undergoing a transaction, the Jena API will
  # raise a Java::ComHpHplJenaSparql::JenaTransactionException exception, which
  # is not rescue'd by design, since this is the most effective way to evade
  # developing glitchy code with overlapping transactions.
  #
  # Also note that write transactions shall not automatically commit changes,
  # so that the developer can decide to commit or rollback changes in runtime.
  #============================================================================
  def transaction( kind )
    case kind
    when :r, :read
      tdb.begin( ReadWrite::READ )
    when :w, :write
      tdb.begin( ReadWrite::WRITE )
    else
      fail( ArgumentError, 'Expected valid transaction type: read or write.' )
    end

    yield
  ensure
    tdb.end if tdb.in_transaction?
  end

  #============================================================================
  # * Start TDB Read Transaction
  #  Helper method that simply passes the given block to the real transaction
  # method.
  #============================================================================
  def dataread
    self.transaction( :read, &Proc::new )
  end

  #============================================================================
  # * Start TDB Write Transaction
  #  Helper method that simply passes the given block to the real transaction
  # method.
  #============================================================================
  def datawrite
    self.transaction( :write, &Proc::new )
  end

  public
  #============================================================================
  # * Dataset Individual Creation
  #============================================================================
  def create_individual( args )
    datawrite do
      ont_class = model.get_ont_class( namespace + args[:class] )

      unless ont_class
        fail ArgumentError, 'Given ontology class does not exist.'
        tdb.abort
      end

      individual = model.create_individual(namespace + args[:name], ont_class)

      # -=-=-=-=-
      # Manually include individual in owl:NamedIndividual type.
      named_individual = model.create_class( owl_prefix + 'NamedIndividual' )
      model.create_individual( namespace + args[:name], named_individual )

      for key, value in args[:property] do
        property = model.get_property(namespace + key.split(':')[1])

        if key =~ /resource/
          resource = model.get_individual(namespace + value)
        else
          resource = case key
                       when /int/ then
                         model.create_typed_literal(value.to_i)
                       when /float/ then
                         model.create_typed_literal(value.to_f)
                       when /literal/ then
                         model.create_typed_literal(value.to_s)
                       else
                         model.create_literal(value)
                     end
        end

        individual.add_property(property, resource)
      end if args[:property]

      tdb.commit
    end
  end

  #============================================================================
  def update_individual( args )
    datawrite do
      individual = model.get_individual( namespace + args[:original_name] )

      unless args[:original_name] == args[:name]
        Util::ResourceUtils::rename_resource( individual, namespace + args[:name] )
        individual = model.get_individual( namespace + args[:name] )
      end

      # FIXME: sometimes the owl:NamedIndividual class gets in the way.
      ont_class = model.get_ont_class( namespace + args[:class] )
      individual.ont_class = ont_class unless individual.get_ont_class == ont_class

      for key, value in args[:property] do
        property = model.get_property(namespace + key.split(':')[1])

        resource = case key
                     when /int/ then
                       ResourceFactory::create_typed_literal(value.to_i)
                     when /float/ then
                       ResourceFactory::create_typed_literal(value.to_f)
                     when /literal/ then
                       ResourceFactory::create_typed_literal(value.to_s)
                     else
                       model.get_individual(namespace + value)
                   end

        if individual.has_property?(property) and
            not individual.get_property_value( property ) == resource
          individual.set_property_value(property, resource)
        else
          individual.add_property(property, resource)
        end
      end if args[:property]

      tdb.commit
    end
  end

  #============================================================================
  def destroy_individual( name )
    datawrite do
      individual = model.get_individual( namespace + name )
      unless individual
        tdb.abort
        fail ArgumentError, 'Given individual does not exist.'
      else
        individual.remove
        tdb.commit
      end
    end
  end

  #============================================================================
  def find_individual( name )
    model.list_individuals.each do | i |
      return i if i.local_name == name
    end
  end

  #============================================================================
  # * Dataset Individual Array
  #============================================================================
  def individuals
    model.list_individuals.to_a
  end

  #============================================================================
  # * Dataset Triple Count
  #============================================================================
  def count
    dataread { tdb.default_model.size }
  end
  
  #============================================================================
  # * Model Triple Count
  #============================================================================
  def count_rdf
    rdf_model.size
  end

  #============================================================================
  # * Dataset Classes
  #  Returns an instance of `Array' containing all the classes from the model,
  # properly removing the trailing namespace.
  #============================================================================
  def classes
    model.list_classes.to_a
  end

  #============================================================================
  # * Dataset Properties
  #  Returns an instance of `Array' containing all the Object and Data(type)
  # properties from the model.
  #============================================================================
  def properties
    return object_properties + datatype_properties
  end

  #============================================================================
  # * Dataset Object Properties
  #============================================================================
  def object_properties
    return model.list_object_properties.to_a
  end

  #============================================================================
  # * Dataset Data(type) Properties
  #============================================================================
  def datatype_properties
    return model.list_datatype_properties.to_a
  end

  #============================================================================
  # * Dataset Query
  #============================================================================
  def query( string )
    prefixes = ''

    rdf_model.ns_prefix_map.each_pair do |k, v|
      prefixes += "PREFIX #{k.empty? ? 'demand' : k}: <#{v}>\n"
    end

    q = QueryFactory::create( prefixes + string )
    dataread do
      yield(QueryExecutionFactory::create(q, tdb.default_model))
    end
  end

  #============================================================================
  # * Array of Query Results
  #  This helper method populates an `Array' object with the results of the
  # query.
  #============================================================================
  def query_to_array( string )
    results = [ ]
    query( string ) do | query_exec |
      query_exec.exec_select.each do | result |
        results << result
      end
    end
    return( results )
  rescue Java::ComHpHplJenaQuery::QueryParseException
    return( [$!.message] )
  end
end

