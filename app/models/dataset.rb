class Dataset < ActiveRecord::Base

  #-=-=-=-=-=-=-
  # Jena-JRuby Library
  require( 'jena_jruby' )

  #-=-=-=-=-=-=-
  # Module Mixins
  include Jena
  include Core, TDB, Query, Ont, Util

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
    tdb.begin( ReadWrite::WRITE )
    tdb.get_default_model.add( model )
    tdb.commit
    tdb.end
  end

  public
  #============================================================================
  # *
  #============================================================================
  def namespace
    unless @namespace
      @namespace = model.get_ns_prefix_map['']
    end
    return @namespace
  end

  def owl_prefix
    unless @owl_prefix
      @owl_prefix = model.get_ns_prefix_map['owl']
    end
    return @owl_prefix
  end

  #============================================================================
  # *
  #============================================================================
  def model
    unless @model
      @model = ModelFactory::create_ontology_model( OntModelSpec::OWL_MEM )
      FileManager::get.read_model(
        @model, File::join( DATASET_FOLDER, self.name, self.rdf_source )
      )
    end
    return @model
  end

  #============================================================================
  # *
  #============================================================================
  def tdb
    unless @tdb
      @tdb = TDBFactory::create_dataset(
        File::join( DATASET_FOLDER, self.name, 'tdb' )
      )
    end
    return @tdb
  end

  #============================================================================
  # *
  #============================================================================
  def destroy_tdb
    FileUtils::rm_r( File::join( DATASET_FOLDER, self.name ) )
  end

  public
  #============================================================================
  # * Dataset Individual Creation
  #============================================================================
  def create_individual( args )
    ont_class = model.create_class( namespace + args[:class] )
    named_individual = model.create_class( owl_prefix + 'NamedIndividual' )

    individual = model.create_individual( namespace + args[:name], ont_class )
    model.create_individual( namespace + args[:name], named_individual )

    if args[:property]
      for key, value in args[:property] do
        property = model.get_property( namespace + key )
        individual.add_property( property, value )
      end
    end

    tdb.begin( ReadWrite::WRITE )
    tdb.get_default_model.add( model )
    tdb.commit
  ensure
    tdb.end
  end

  #============================================================================
  # * Dataset Triple Count
  #============================================================================
  def count
    tdb.begin( ReadWrite::READ )
    return tdb.get_default_model.size
  ensure
    tdb.end
  end
  
  #============================================================================
  # * Model Triple Count
  #============================================================================
  def count_rdf
    model.size
  end

  #============================================================================
  # * Dataset Classes
  #  Returns an instance of `Array' containing all the classes from the model,
  # properly removing the trailing namespace.
  #============================================================================
  def classes
    return model.list_classes.to_a.collect do | c |
      c.to_s.match( /#(.+)/ )[1]
    end.sort
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
    return model.list_object_properties.to_a.collect do | prop |
      prop.to_s.match( /#(.+)/ )[1]
    end.sort
  end

  #============================================================================
  # * Dataset Data(type) Properties
  #============================================================================
  def datatype_properties
    return model.list_datatype_properties.to_a.collect do | prop |
      prop.to_s.match( /#(.+)/ )[1]
    end.sort
  end

  #============================================================================
  # * Dataset Query
  #============================================================================
  def query( string )
    prefixes = ''

    model.get_ns_prefix_map.each_pair do | k, v |
      prefixes += "prefix #{k.empty? ? 'demand' : k}: <#{v}>\n"
    end

    q = QueryFactory::create( prefixes + string )
    tdb.begin( ReadWrite::READ )
    execution = QueryExecutionFactory::create( q, tdb.get_default_model )

    yield( execution )
  ensure
    tdb.end
  end

  #============================================================================
  # *
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

