class CreatePlugins < ActiveRecord::Migration[5.2]
  def change
    create_table :plugins do |t|
      t.string :name
      t.string :phase
      t.text :code
      t.references :domain, foreign_key: true

      t.timestamps
    end
  end
end
