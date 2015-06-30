# Encoding: UTF-8

class DatasetsController < ApplicationController
  before_action :set_dataset, only: [:show, :edit, :update, :destroy]
  before_filter :check_cancel, only: [ :create, :update, :create_feeder, :update_feeder ]

  #============================================================================
  # GET /new_feeder
  # * Creates a form page for the creation of Feeders.
  #============================================================================
  def new_feeder
    dataset = Dataset::find_by_id( params[:id] )
    @ontclass = dataset.find_class( 'Alimentadores' )
    @properties = dataset.properties
    @individuals = dataset.individuals
  end

  #============================================================================
  # POST /create_feeder
  # * Creates a new individual based on the parameters given.
  #============================================================================
  def create_feeder
    dataset = Dataset::find_by_id( params[:individual][:dataset_id] )
    feeder = dataset.create_individual( params[:individual] )
    redirect_to show_feeder_path( dataset, feeder.local_name )
  end

  #============================================================================
  # GET /edit_feeder
  # * Creates a form page for updating an individual's properties.
  #============================================================================
  def edit_feeder
    @dataset = Dataset::find_by_id(params[:id] )
    @individual = @dataset.find_individual_by_name(params[:name])
    @ont_class = @individual.list_ont_classes(true).map do |c|
      !(c.local_name =~ /NamedIndividual/) ? c : nil
    end.compact[0]
  end

  #============================================================================
  # POST /update_individual
  # * Updates an existing individual's properties.
  #============================================================================
  def update_feeder
    dataset = Dataset::find_by_id( params[:individual][:dataset_id] )
    dataset.update_individual( params[:individual] )
    redirect_to show_feeder_path( dataset, params[:individual][:name] )
  end

  #============================================================================
  # AJAX PUT /add_property
  # * Places a specific property field to create/update individual form.
  #============================================================================
  def add_property
    @type, @property = params[:type], params[:property]
    if @type == 'resource'
      @individuals = Dataset::find_by_id(params[:dataset_id]).individuals
    end
  end

  #============================================================================
  # GET /show_individual
  # * Shows property details of an individual.
  #============================================================================
  def show_feeder
    @dataset = Dataset::find_by_id( params[:id] )
    @individual = @dataset.find_individual_by_name( params[:name] )

    @back = dataset_path( @dataset )
  end

  #============================================================================
  # DELETE /destroy_individual
  # * Deletes an individual and all references to it.
  #============================================================================
  def destroy_feeder
    dataset = Dataset::find_by_id( params[:id] )
    dataset.destroy_individual( params[:name] )
    redirect_to dataset
  end

  #============================================================================
  # GET /new_building_system
  # * Creates a form page for the creation of Feeders.
  #============================================================================
  def new_building_system
    dataset = Dataset::find_by_id( params[:id] )
    @ontclass = dataset.find_class( 'Sistema_Predial' )
    @properties = dataset.properties
    @individuals = dataset.individuals
  end

  #============================================================================
  # POST /create_building_system
  # * Creates a new individual based on the parameters given.
  #============================================================================
  def create_building_system
    dataset = Dataset::find_by_id( params[:individual][:dataset_id] )
    building_system = dataset.create_individual( params[:individual] )
    redirect_to show_building_system_path( dataset, building_system.local_name )
  end

  #============================================================================
  # GET /edit_building_system
  # * Creates a form page for updating an individual's properties.
  #============================================================================
  def edit_building_system
    @dataset = Dataset::find_by_id(params[:id] )
    @individual = @dataset.find_individual_by_name(params[:name])
    @ont_class = @individual.list_ont_classes(true).map do |c|
      !(c.local_name =~ /NamedIndividual/) ? c : nil
    end.compact[0]
  end

  #============================================================================
  # POST /update_building_system
  # * Updates an existing individual's properties.
  #============================================================================
  def update_building_system
    dataset = Dataset::find_by_id( params[:individual][:dataset_id] )
    dataset.update_individual( params[:individual] )
    redirect_to show_building_system_path( dataset, params[:individual][:name] )
  end

  #============================================================================
  # GET /show_building_system
  # * Shows property details of an individual.
  #============================================================================
  def show_building_system
    @dataset = Dataset::find_by_id( params[:id] )
    @individual = @dataset.find_individual_by_name( params[:name] )

    @back = dataset_path( @dataset )
  end

  #============================================================================
  # DELETE /destroy_building_system
  # * Deletes an individual and all references to it.
  #============================================================================
  def destroy_building_system
    dataset = Dataset::find_by_id( params[:id] )
    dataset.destroy_individual( params[:name] )
    redirect_to dataset
  end

  #============================================================================
  def reasoner
    @dataset = Dataset::find_by_id( params[:id] )
  end

  #============================================================================
  def reasoner_inferences
    if not params[:id] or not params[:name]
      redirect_to( reasoner_path, notice: 'Nenhuma ontologia foi selecionado(a).' )
    end
    dataset = Dataset::find_by_id( params[:id] )
    @dataset_name = dataset.name
    @individual_name = params[:name]
    @inferences = dataset.reason( params[:name] )
  end

  #============================================================================
  def query
    @dataset = Dataset::find_by_id( params[:id] )

    @back = dataset_path( params[:id] )
  end

  #============================================================================
  def query_results
    if params[:id].empty?
      redirect_to( query_path, notice: 'Nenhuma ontologia selecionada.' )
      return
    end

    dataset = Dataset::find_by_id( params[:id] )
    @results = dataset.query_to_array( params[:query] )
    @query = params[:query]
  end

  #============================================================================
  # AJAX GET /send_rdf_source
  # * Sends the RDF/OWL source file to download.
  #============================================================================
  def send_rdf_source
    dataset = Dataset::find_by_id( params[:id] )
    path = "datasets/#{dataset.name}/#{dataset.rdf_source}"
    send_file( path, type: 'application/owl+xml', x_sendfile: true )
  end

  # GET /datasets
  # GET /datasets.json
  def index
    @datasets = Dataset::all
  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
    @back = datasets_path
  end

  # GET /datasets/new
  def new
    @dataset = Dataset.new
  end

  # GET /datasets/1/edit
  def edit
  end

  # POST /datasets
  # POST /datasets.json
  def create
    @dataset = Dataset.new(dataset_params)
    respond_to do |format|
      if @dataset.save
        format.html { redirect_to @dataset, notice: 'Dataset was successfully created.' }
        format.json { render :show, status: :created, location: @dataset }
      else
        format.html { render :new }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /datasets/1
  # PATCH/PUT /datasets/1.json
  def update
    respond_to do |format|
      if @dataset.update(dataset_params)
        format.html { redirect_to @dataset, notice: 'Dataset was successfully updated.' }
        format.json { render :show, status: :ok, location: @dataset }
      else
        format.html { render :edit }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /datasets/1
  # DELETE /datasets/1.json
  def destroy
    @dataset.destroy
    respond_to do |format|
      format.html { redirect_to datasets_url, notice: 'Dataset was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_dataset
    @dataset = Dataset.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def dataset_params
    params.require(:dataset).permit(:name, :user_id, rdf_source: [])
  end

  def check_cancel
    return unless params[:commit] == 'Cancelar'

    if params[:action] =~ /update/
      redirect_to( dataset_path( params[:id] ) )
    else
      redirect_to( datasets_path )
    end
  end
end
