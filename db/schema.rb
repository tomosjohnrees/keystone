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

ActiveRecord::Schema[8.1].define(version: 2026_05_07_145754) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assessments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "decision"
    t.decimal "dti", precision: 8, scale: 2
    t.text "error_message"
    t.text "explanation"
    t.decimal "ltv", precision: 8, scale: 2
    t.decimal "max_borrowing", precision: 12, scale: 2
    t.bigint "mortgage_application_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["mortgage_application_id"], name: "index_assessments_on_mortgage_application_id", unique: true
  end

  create_table "mortgage_applications", force: :cascade do |t|
    t.decimal "annual_income", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.decimal "deposit_amount", precision: 12, scale: 2, null: false
    t.decimal "monthly_expenses", precision: 12, scale: 2, null: false
    t.decimal "property_value", precision: 12, scale: 2, null: false
    t.integer "term_years", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "assessments", "mortgage_applications"
end
