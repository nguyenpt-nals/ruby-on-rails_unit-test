class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.references :user, foreign_key: true, null: false
      t.string :type, null: false
      t.integer :amount, null: false
      t.boolean :flag, default: false
      t.integer :status, default: 0, null: false
      t.integer :priority, default: 0, null: false

      t.timestamps
    end
  end
end