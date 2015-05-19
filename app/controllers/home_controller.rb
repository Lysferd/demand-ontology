class HomeController < ApplicationController
  def index
  end

  def query_results
    if params[:dataset_id].empty?
      redirect_to home_query_path, notice: "Nenhuma ontologia selecionada."
      return
    end

    dataset = Dataset::find_by_id( params[:dataset_id] )
    @results = dataset.query_to_array( params[:query] )
    @query = params[:query]
  end

end
