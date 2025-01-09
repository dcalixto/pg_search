class CreatePgSearchDocuments < DB::Migration
  def up
    create_table :pg_search_documents do |t|
      t.column :content, :text
      t.column :searchable_type, :string
      t.column :searchable_id, :bigint
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end

    add_index :pg_search_documents, [:searchable_type, :searchable_id]
    add_index :pg_search_documents, [:content], using: :gin
  end

  def down
    drop_table :pg_search_documents
  end
end
