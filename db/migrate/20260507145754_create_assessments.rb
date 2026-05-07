class CreateAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :assessments do |t|
      t.references :mortgage_application,
                   null: false,
                   foreign_key: true,
                   index: { unique: true }
      t.string  :status, null: false, default: "pending"
      t.decimal :ltv,            precision: 8,  scale: 2
      t.decimal :dti,            precision: 8,  scale: 2
      t.string  :decision
      t.decimal :max_borrowing,  precision: 12, scale: 2
      t.text    :explanation
      t.text    :error_message

      t.timestamps
    end
  end
end
