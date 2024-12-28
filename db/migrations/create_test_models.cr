class CreateTestModels < DB::Migration
  def up
    create_table :test_models do |t|
      t.string :title
      t.text :body
      t.timestamps
    end
  end

  def down
    drop_table :test_models
  end
end
