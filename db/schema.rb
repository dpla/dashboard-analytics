# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_04_03_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "admin"
    t.string "hub"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "wikimedia_cache", force: :cascade do |t|
    t.string "hub", null: false
    t.string "contributor", default: "", null: false
    t.string "month", null: false
    t.integer "upload_count"
    t.integer "page_views"
    t.integer "files_used"
    t.integer "pages_enhanced"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hub", "contributor", "month"], name: "index_wikimedia_cache_on_hub_and_contributor_and_month", unique: true
  end

  create_table "wikimedia_participants", force: :cascade do |t|
    t.string "hub", null: false
    t.string "contributor", null: false
    t.boolean "participant", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hub", "contributor"], name: "index_wikimedia_participants_on_hub_and_contributor", unique: true
  end
end
