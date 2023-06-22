class CreateGames < ActiveRecord::Migration[7.0]
  def change
    create_table :games do |t|
      t.string :current_player
      t.boolean :game_over
      t.string :winner
      t.string :win_pattern

      t.timestamps
    end
  end
end
