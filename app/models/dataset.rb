class Dataset < ActiveRecord::Base

  require( 'jena_jruby' )

  include( Jena )

  DATASET_FOLDER = File::join( Dir::pwd, 'datasets' )

  before_create :generate_tdb
  before_destroy :destroy_tdb

  validates :name, presence: true, uniqueness: true
  validates :rdf_source, presence: true

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
    # use jena api to create dataset
    model = load_model
    tdb   = create_dataset

    # -=-=-=-=-
    # Populate Dataset with the Ontology Model.
    begin
      tdb.begin( Query::ReadWrite::WRITE )
      tdb.get_default_model.add( model )
      tdb.commit
    ensure
      tdb.end
    end
  end

  #============================================================================
  #============================================================================
  def load_model
    model = Core::ModelFactory::create_ontology_model( Ont::OntModelSpec::OWL_MEM )
    Util::FileManager::get.read_model(
      model,
      File::join(
        DATASET_FOLDER,
        self.name,
        self.rdf_source
      )
    )
    return model
  end
    

  #============================================================================
  # *
  #============================================================================
  def create_dataset
    TDB::TDBFactory::create_dataset(
      File::join( DATASET_FOLDER, self.name, 'tdb' )
    )
  end
  alias :load_dataset :create_dataset

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
    tdb = load_dataset
    model = load_model
    ns = model.get_ns_prefix_map['']

    ont_class = model.create_class( ns + args[:class] )
    individual = model.create_individual( ns + args[:name], ont_class )

    tdb.begin( Query::ReadWrite::WRITE )
    tdb.get_default_model.add( model )
    tdb.commit
  ensure
    tdb.end
  end

  #============================================================================
  # * Dataset Triple Count
  #============================================================================
  def count
    tdb = load_dataset
    tdb.begin( Query::ReadWrite::READ )
    return tdb.get_default_model.size
  ensure
    tdb.end
  end
  
  #============================================================================
  # * Model Triple Count
  #============================================================================
  def count_rdf
    load_model.size
  end

  #============================================================================
  # * Dataset Classes
  #  Returns an instance of `Array' containing all the classes from the model,
  # properly removing the trailing namespace.
  #============================================================================
  def classes
    return load_model.list_classes.to_a.collect do | c |
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
    return load_model.list_object_properties.to_a.collect do | prop |
      prop.to_s.match( /#(.+)/ )[1]
    end.sort
  end

  #============================================================================
  # * Dataset Data(type) Properties
  #============================================================================
  def datatype_properties
    return load_model.list_datatype_properties.to_a.collect do | prop |
      prop.to_s.match( /#(.+)/ )[1]
    end.sort
  end

  #============================================================================
  # * Dataset Query
  #============================================================================
  def query( string )
    tdb = load_dataset
    model = load_model
    prefixes = ''

    model.get_ns_prefix_map.each_pair do | k, v |
      prefixes += "prefix #{k.empty? ? 'demand' : k}: <#{v}>\n"
    end

    q = Query::QueryFactory::create( prefixes + string )
    tdb.begin( Query::ReadWrite::READ )
    execution = Query::QueryExecutionFactory::create( q, tdb.get_default_model )

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

