class CreateTestTables < DB::Migration
  def up
    create_table :test_models do |t|
      t.column :title, :string
      t.column :body, :text
      t.column :comments_count, :integer, default: 0
      t.timestamps
    end

    create_table :punches do |t|
      t.column :punchable_type, :string
      t.column :punchable_id, :bigint
      t.column :hits, :integer, default: 1
      t.timestamps
    end

    create_table :votes do |t|
      t.column :resource_type, :string
      t.column :resource_id, :bigint
      t.column :positive, :boolean
      t.column :negative, :boolean
      t.timestamps
    end

    create_table :comments do |t|
      t.column :commentable_type, :string
      t.column :commentable_id, :bigint
      t.column :body, :text
      t.timestamps
    end
  end

  def down
    drop_table :test_models
    drop_table :punches
    drop_table :votes
    drop_table :comments
  end
end
