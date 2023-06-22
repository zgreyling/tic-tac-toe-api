class Api::V1::GamesController < ApplicationController
  before_action :set_game, only: %i[ show update destroy ]

  # GET /games
  def index
    @games = Game.all

    render json: @games.to_json(include: :squares)
  end

  # GET /games/1
  def show
    render json: @game.to_json(include: :squares)
  end

  # POST /games
  def create
    ActiveRecord::Base.transaction do
      # Create a game
      @game = Game.create!(current_player: 'X', game_over: false, win_pattern: nil, winner: nil)

      # Create the board squares
      for square in 1..9 do
        @square = Square.create!(square: square, value: nil, winning_square: false, game_id: @game.id)
      end

      # Return the game and its board squares
      render json: @game.to_json(include: :squares)
    end
  end

  # PATCH/PUT /games/1
  def update
    if @game.update(game_params)
      render json: @game
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  # DELETE /games/1
  def destroy
    @game.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def game_params
      params.require(:game).permit(:current_player, :game_over, :winner, :win_pattern)
    end
end
