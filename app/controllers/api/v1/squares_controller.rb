class Api::V1::SquaresController < ApplicationController
  before_action :set_square, only: %i[ show update destroy ]

  # GET /squares
  def index
    @squares = Square.all

    render json: @squares
  end

  # GET /squares/1
  def show
    render json: @square
  end

  # POST /squares
  def create
    @square = Square.new(square_params)

    if @square.save
      render json: @square, status: :created
    else
      render json: @square.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /squares/1
  def update
    ActiveRecord::Base.transaction do
      # Update the square
      @square.update!(square_params)

      # Retrieve game to which the square belongs
      @game = Game.find_by(id: square_params[:game_id])

      # Check if a winning combination exists on the board
      winning_data = determine_game_status(@game)

      # If there is a winner, update the game's winning fields
      if winning_data[0]
        @game.update!(current_player: nil, game_over: true, winner: winning_data[2], win_pattern: [winning_data[3]])
      # If there is no winner but the game is over (a draw), update the game status
      elsif winning_data[1]
        @game.update!(game_over: true, current_player: nil)
      # If there is no winner yet and the game is not over, update the current player
      else
        if (@game[:current_player] == 'X')
          @game.update!(current_player: 'O')
        elsif (@game[:current_player] == 'O')
          @game.update!(current_player: 'X')
        end
      end

      # Return the game and its board squares
      render json: Game.find_by(id: square_params[:game_id]).to_json(include: :squares)
    end
  end

  # DELETE /squares/1
  def destroy
    @square.destroy
  end

  private
    WINNING_COMBINATIONS = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
      [1, 4, 7],
      [2, 5, 8],
      [3, 6, 9],
      [1, 5, 9],
      [3, 5, 7]
    ]

    def determine_game_status(game)
      winner_found = false;
      game_over = false;

      # Find squares with values assigned to them
      @squares = Square.where(game_id: game[:id]).where.not(value: nil)

      # Not enough squares have values yet to determine a winner
      if (JSON.parse(@squares.to_json()).length < 5) then
        return winner_found, game_over
      else
        # Find all squares with a value of X belonging to the game if at least 3 squares have a value of X
        if (JSON.parse(Square.where(game_id: game[:id], value: 'X').to_json()).length >= 3) then
          game_status = determine_winning_combination('X', game)
          if (game_status[0] == true) then
            return game_status
          end
        end

        # Find all squares with a value of O belonging to the game if at least 3 squares have a value of O and a winner has not been found
        if (JSON.parse(Square.where(game_id: game[:id], value: 'O').to_json()).length >= 3 && !winner_found) then
          game_status = determine_winning_combination('O', game)
          if (game_status[0] == true) then
            return game_status
          end
        end

        # No winner was found and all 9 squares have values = Draw
        if !winner_found && JSON.parse(@squares.to_json()).length == 9
          game_over = true
        end

        return winner_found, game_over
      end
    end

    def determine_winning_combination(value, game)
      # Check all possible winning combinations
      WINNING_COMBINATIONS.each do |win_combination|
        count = 0
        # Find a square with the value passed that matches the first number in the winning combination
        square_1 = Square.where(square: win_combination[0], game_id: game[:id], value: value)
        # Determine the length of the response
        square_1_length = JSON.parse(square_1.to_json()).length
        # Add the length to the counter
        count += square_1_length

        square_2 = Square.where(square: win_combination[1], game_id: game[:id], value: value)
        square_2_length = JSON.parse(square_2.to_json()).length
        count += square_2_length

        square_3 = Square.where(square: win_combination[2], game_id: game[:id], value: value)
        square_3_length = JSON.parse(square_3.to_json()).length
        count += square_3_length
        
        # If the counter is 3, the entire winning combination was found, update the winning squares for the game and return the relevant data 
        if (count == 3) then
          square_1.update!(winning_square: true)
          square_2.update!(winning_square: true)
          square_3.update!(winning_square: true)
          return true, true, value, win_combination
        end
      end

      # A winning combination has not been found for the value passed
      return false, false
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_square
      @square = Square.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def square_params
      params.require(:square).permit(:square, :value, :winning_square, :game_id, :id, :updated_at, :created_at)
    end
end
