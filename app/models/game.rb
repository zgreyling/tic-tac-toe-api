class Game < ApplicationRecord
    has_many :squares, dependent: :destroy
end
