class Dataset < ActiveRecord::Base

  require( 'jena_jruby' )

  include( Jena )

  DATASET_FOLDER = File::join( Dir::pwd, 'datasets' )

  before_create :generate_tdb
  before_destroy :destroy_tdb

  validates :name, presence: true, uniqueness: true
  validates :rdf_source, presence: true

  private
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
    model = Core::ModelFactory::create_ontology_model( Ont::OntModelSpec::OWL_MEM )
    Util::FileManager::get.read_model( model, path )

    create_dataset
    populate_dataset( model )
  end

  def create_dataset
    @tdb = TDB::TDBFactory::create_dataset( File::join( DATASET_FOLDER, self.name, 'tdb' ) )
    #@tdb.begin( Query::ReadWrite::READ )
  #ensure
    #@tdb.end
  end
  alias :load_dataset :create_dataset

  def populate_dataset( model )
    @tdb.begin( Query::ReadWrite::WRITE )
    @tdb.get_default_model.add( model )
    @tdb.commit
  ensure
    @tdb.end
  end

  def destroy_tdb
    FileUtils::rm_r( File::join( DATASET_FOLDER, self.name ) )
  end

  public
  def count
    load_dataset

    @tdb.begin( Query::ReadWrite::READ )
    return( @tdb.get_default_model.size )
  ensure
    @tdb.end
  end
  
  def count_rdf
    model = Core::ModelFactory::create_ontology_model( Ont::OntModelSpec::OWL_MEM )
    Util::FileManager::get.read_model( model, File::join( DATASET_FOLDER, self.name, self.rdf_source ) )
    return( model.size )
  end

  def query( string )
    load_dataset

    @tdb.begin( Query::ReadWrite::READ )
    namespace = @tdb.get_default_model.get_ns_prefix_uri( '' )
    prefix = "prefix demand: <#{namespace}>\n" +
             "prefix rdfs: <#{Vocab::RDFS::get_uri}>\n" +
             "prefix owl: <#{Vocab::OWL::get_uri}>\n"
    q = Query::QueryFactory::create( prefix + string )
    query_exec = Query::QueryExecutionFactory::create( q, @tdb.get_default_model )

    yield( query_exec )
  ensure
    #@tdb.end
    #query_exec.close
  end

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
