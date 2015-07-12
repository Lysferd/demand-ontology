# Encoding: UTF-8

class DatasetsController < ApplicationController
  before_action :set_dataset, only: [:show, :edit, :update, :destroy]

  #============================================================================
  # GET /new_feeder
  # * Creates a form page for the creation of Feeders.
  #============================================================================
  def new_feeder
    dataset = Dataset::find_by_id params[:id]
    @ont_class = dataset.ontology_class 'Alimentador'
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
    if feeder
      redirect_to show_feeder_path( dataset, feeder.local_name ), notice: 'Alimentador criado com sucesso.'
    else
      redirect_to new_feeder_path, alert: 'Não foi possível criar alimentador.'
    end
  end

  #============================================================================
  # GET /edit_feeder
  # * Creates a form page for updating an individual's properties.
  #============================================================================
  def edit_feeder
    @dataset = Dataset::find_by_id params[:id]
    @individual = @dataset.individual params[:name]
  end

  #============================================================================
  # POST /update_individual
  # * Updates an existing individual's properties.
  #============================================================================
  def update_feeder
    dataset = Dataset::find_by_id( params[:individual][:dataset_id] )
    if dataset.update_individual( params[:individual] )
      redirect_to show_feeder_path( dataset, params[:individual][:name] ),
                  notice: 'Alimentador modificado com sucesso.'
    else
      redirect_to edit_feeder_path, alert: 'Não foi possível modificar alimentador.'
    end
  end

  #============================================================================
  # GET /show_individual
  # * Shows property details of an individual.
  #============================================================================
  def show_feeder
    @dataset = Dataset::find_by_id params[:id]
    @individual = @dataset.individual params[:name]

    @back = dataset_path @dataset
  end

  #============================================================================
  # DELETE /destroy_individual
  # * Deletes an individual and all references to it.
  #============================================================================
  def destroy_feeder
    dataset = Dataset::find_by_id( params[:id] )
    dataset.destroy_individual( params[:name] )

    respond_to do |format|
      format.html { redirect_to dataset, notice: 'Alimentador removido com sucesso.' }
      format.json { head :no_content }
    end
  end

  #============================================================================
  # GET /new_building_system
  # * Creates a form page for the creation of Feeders.
  #============================================================================
  def new_building_system
    dataset = Dataset::find_by_id params[:id]
    @ontclass = dataset.ontology_class 'Sistema_Predial'
    @properties = dataset.properties
    @individuals = dataset.feeders
  end

  #============================================================================
  # POST /create_building_system
  # * Creates a new individual based on the parameters given.
  #============================================================================
  def create_building_system
    dataset = Dataset::find_by_id( params[:individual][:dataset_id] )
    building_system = dataset.create_individual( params[:individual] )
    if building_system
      redirect_to show_building_system_path( dataset, building_system.local_name ),
                  notice: 'Sistema predial criado com sucesso.'
    else
      redirect_to new_building_system_path,
                  alert: 'Não foi possível criar sistema predial.'
    end
  end

  #============================================================================
  # GET /edit_building_system
  # * Creates a form page for updating an individual's properties.
  #============================================================================
  def edit_building_system
    @dataset = Dataset::find_by_id params[:id]
    @individual = @dataset.individual params[:name]
  end

  #============================================================================
  # POST /update_building_system
  # * Updates an existing individual's properties.
  #============================================================================
  def update_building_system
    dataset = Dataset::find_by_id( params[:individual][:dataset_id] )
    if dataset.update_individual( params[:individual] )
      redirect_to show_building_system_path( dataset, params[:individual][:name] ),
                  notice: 'Sistema predial modificado com sucesso.'
    else
      redirect_to edit_building_system_path,
                  alert: 'Não foi possível modificar sistema predial.'
    end
  end

  #============================================================================
  # GET /show_building_system
  # * Shows property details of an individual.
  #============================================================================
  def show_building_system
    @dataset = Dataset::find_by_id params[:id]
    @individual = @dataset.individual params[:name]
    #@resources = @dataset.individuals parent: @individual

    @back = dataset_path @dataset
  end

  #============================================================================
  # DELETE /destroy_building_system
  # * Deletes an individual and all references to it.
  #============================================================================
  def destroy_building_system
    dataset = Dataset::find_by_id( params[:id] )
    dataset.destroy_individual( params[:name] )

    respond_to do |format|
      format.html { redirect_to dataset, notice: 'Sistema predial removido com sucesso.' }
      format.json { head :no_content }
    end
  end

  #============================================================================
  # GET /new_resource
  # * Form for resource creation.
  #============================================================================
  def new_resource
    dataset = Dataset::find_by_id( params[:id] )
    @ont_classes = dataset.classes
    @properties = dataset.properties
    @individuals = dataset.building_systems
  end

  def edit_resource
    @dataset = Dataset::find_by_id params[:id]
    @individual = @dataset.individual params[:name]
  end

  def create_resource
    dataset = Dataset::find_by_id( params[:individual][:dataset_id] )
    resource = dataset.create_individual( params[:individual] )
    if resource
      redirect_to show_building_system_path( dataset, params[:individual][:property]['resource:Pertence_A'] ),
                  notice: 'Recurso criado com sucesso.'
    else
      redirect_to new_building_system_path,
                  alert: 'Não foi possível criar recurso.'
    end
  end

  def update_resource
    dataset = Dataset::find_by_id( params[:individual][:dataset_id] )
    if dataset.update_individual( params[:individual] )
      redirect_to show_building_system_path( dataset, params[:individual][:property]['resource:Pertence_A'] ),
                  notice: 'Recurso modificado com sucesso.'
    else
      redirect_to edit_building_system_path,
                  alert: 'Não foi possível modificar recurso.'
    end
  end

  def destroy_resource
    dataset = Dataset::find_by_id( params[:id] )
    dataset.destroy_individual( params[:name] )

    respond_to do |format|
      format.html { redirect_to dataset, notice: 'Recurso removido com sucesso.' }
      format.json { head :no_content }
    end
  end

  #============================================================================
  def statistics
    dataset = Dataset::find_by_id params[:id]
    @individual = dataset.individual params[:name]
  end

  #============================================================================
  def reasoner
    @dataset = Dataset::find_by_id params[:id]
  end

  #============================================================================
  def reasoner_inferences
    if not params[:id] or not params[:name]
      redirect_to( reasoner_path, alert: 'Nenhuma ontologia foi selecionada.' )
    end
    dataset = Dataset::find_by_id( params[:id] )
    @dataset_name = dataset.name
    @individual_name = params[:name]
    @inferences = dataset.reason( params[:name] )
  end

  #============================================================================
  def query
    @dataset = Dataset::find_by_id params[:id]
    @back = dataset_path params[:id]
  end

  #============================================================================
  def query_results
    if params[:id].empty?
      redirect_to( query_path, alert: 'Nenhuma ontologia selecionada.' )
      return
    end

    dataset = Dataset::find_by_id( params[:id] )
    @results = dataset.query_to_array( params[:query] )
    @query = params[:query]
  end

  #============================================================================
  def charts
    dataset = Dataset::find_by_id params[:id]
    @individual = dataset.individual params[:name]
  end

  #============================================================================
  # AJAX GET /send_rdf_source
  # * Sends the RDF/OWL source file to download.
  #============================================================================
  def send_rdf_source
    dataset = Dataset::find_by_id params[:id]
    path = "datasets/#{dataset.name}/#{dataset.rdf_source}"
    send_file( path, type: 'application/owl+xml', x_sendfile: true )
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
        format.html { redirect_to @dataset, notice: 'Dataset criado com sucesso.' }
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
        format.html { redirect_to @dataset, notice: 'Dataset modificado com sucesso.' }
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
      format.html { redirect_to datasets_url, notice: 'Dataset removido com sucesso.' }
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
end
