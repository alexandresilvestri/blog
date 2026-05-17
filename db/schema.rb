ActiveRecord::Schema[8.1].define(version: 2026_05_16_152207) do
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "post", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end
end
