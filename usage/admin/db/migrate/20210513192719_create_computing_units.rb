class CreateComputingUnits < ActiveRecord::Migration[5.2]
  def change
    create_table :computing_units do |t|
      t.string :name
      t.string :phase
      t.string :code
      t.string :sampling

      t.timestamps
    end
  end
end
