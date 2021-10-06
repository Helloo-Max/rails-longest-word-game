# rubocop: disable all

require 'open-uri'
require 'json'

class GamesController < ApplicationController
  def new
    @letters = generate_grid(10)
  end

  def score
    @end_time = Time.now
    @start_time = params[:time].to_time #=> Parsing to a Time object

    @word = params[:word]
    @grid = params[:letters]
    @result = run_game(@word, @grid, @start_time, @end_time)
  end

  private

  def generate_grid(grid_size)
    random_grid = []
    5.times { random_grid << ('A'..'Z').to_a } #=> Populate with duplicates [["A", "B"...], ["A", "B"...], ...]
    random_grid.flatten.shuffle.take(grid_size) #=> Removes nested arrays and takes letters (e.g. ["Z", "J", "S", "G"])
  end

  # Uses the Wagon Dictionary API and checks for validity
  def valid_word?(word)
    url = "https://wagon-dictionary.herokuapp.com/#{word}"
    url_serialized = URI.open(url).read #=> Returns string of API (e.g. "{\"found\":true,\"word\":\"banana\",\"length\":6}")
    word = JSON.parse(url_serialized) #=> Returns hash (e.g. {"found"=>true, "word"=>"banana", "length"=>6})
    word['found'] #=> Returns true or false
  end

  def list_duplicates(word)
    splitted_word = @word.downcase.chars
    splitted_word.select { |e| splitted_word.count(e) > 1 } #=> e.g. ("spell") => ["l", "l"]
  end

  def chars_by_occurence(char_duplicates)
    char_duplicates.group_by { |i| i }.map { |k, v| [k, v.count] }.to_h #=> e.g. {"e"=>2, "l"=>2, "o"=>2}
  end

  def word_in_grid?(word, grid)
    sorted_grid = grid.downcase.chars.sort.reverse #=> e.g. ["s", "p", "o", "o", "o", "o", "l", "e"]
    sorted_word = word.downcase.chars.sort.reverse #=> Possible subset of sorted_grid e.g. ["s", "p", "l", "l", "l", "e"]
    subset = sorted_grid - sorted_word #=> e.g. ["o", "o", "o", "o"]

    duplicates_word = list_duplicates(word) #=> e.g. ["l", "l", "l"]
    duplicates_grid = list_duplicates(grid.chars) #=> e.g. ["o", "o", "o", "o"]

    intersection = duplicates_grid & duplicates_word #=> [ ] or with intersection (e.g. ["o"])

    word_chars_duplicates = chars_by_occurence(duplicates_word)
    grid_chars_duplicates = chars_by_occurence(duplicates_grid)

    exceeded_grid = intersection.empty? ? intersection.empty? && duplicates_word.empty? : grid_chars_duplicates[intersection.first] > word_chars_duplicates[intersection.first]

    # Returns true if subset is < sorted_grid (sample size), all chars are included in sorted_grid and no exceeded letters
    subset.length < sorted_grid.length && sorted_word.all? { |char| sorted_grid.include?(char) } && exceeded_grid
  end

  def measure_time(start_time, end_time)
    end_time - start_time
  end

  def calc_score(word, grid, start_time, end_time)
    time_score = measure_time(start_time, end_time)
    # Gives points when valid_word? and word_in_grid? both true
    word_score = valid_word?(word) && word_in_grod?(word, grid) ? word.length * 100 : 0
    if word_score.positive?
      word_score - time_score if (word_score - time_score).positive? #=> Additional loop ensures word_score > 0
    else
      0
    end
  end

  def select_message(word, grid)
    if valid_word?(word) && word_in_grid?(word, grid)
      "Well done! #{@word.upcase} is a valid English word!"
    elsif valid_word?(word) && !word_in_grid?(word, grid)
      "Sorry but #{@word.upcase} can't be built out of #{@grid}"
    elsif !valid_word?(word) && word_in_grid?(word, grid)
      "Sorry but #{@word.upcase} does not seem to be a valid English word..."
    else
      "Try again!"
    end
  end

  def run_game(word, grid, start_time, end_time)
    time = measure_time(start_time, end_time)

    score = calc_score(word, grid, start_time, end_time) #=> Combination of time + word length valid and in grid
    message = select_message(word, grid)
    
    {
      time: time,
      score: score,
      message: message
    }
  end
end
