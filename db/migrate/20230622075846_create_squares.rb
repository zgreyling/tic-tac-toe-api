class CreateSquares < ActiveRecord::Migration[7.0]
  def change
    create_table :squares do |t|
      t.integer :square
      t.string :value
      t.boolean :winning_square
      t.integer :game_id

      t.timestamps
    end
  end
end
