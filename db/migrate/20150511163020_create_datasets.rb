class CreateDatasets < ActiveRecord::Migration
  def change
    create_table :datasets do |t|
      t.string :name
      t.binary :rdf_source
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
