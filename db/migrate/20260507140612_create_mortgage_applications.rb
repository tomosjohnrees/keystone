class CreateMortgageApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :mortgage_applications do |t|
      t.decimal :annual_income, precision: 12, scale: 2, null: false
      t.decimal :monthly_expenses, precision: 12, scale: 2, null: false
      t.decimal :deposit_amount, precision: 12, scale: 2, null: false
      t.decimal :property_value, precision: 12, scale: 2, null: false
      t.integer :term_years, null: false

      t.timestamps
    end
  end
end
