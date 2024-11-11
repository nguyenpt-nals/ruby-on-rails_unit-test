class CreateUsers < ActiveRecord::Migration[7.0]
  def up
    create_table :users do |t|
      t.string :username
      t.string :email
      t.string :password_digest
      t.integer :gender
      
      t.timestamps
    end
  end

  def down
    drop_table :users
  end
end