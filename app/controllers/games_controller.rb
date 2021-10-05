# rubocop: disable all

require 'open-uri'
require 'json'

class GamesController < ApplicationController
  def new
    @letters = generate_grid(10)
    # binding.pry
  end

  def score
    @end_time = Time.now
    @start_time = params[:time].to_time #=> Parsing to a Time object.

    @word = params[:word]
    @letters = params[:letters]
    @result = run_game(@word, @letters, @start_time, @end_time)
  end

  private

  def generate_grid(letter_size)
    random_letters = []
    5.times { random_letters << ('A'..'Z').to_a } #=> Populate with duplicates [["A", "B"...], ["A", "B"...], ...].
    random_letters.flatten.shuffle.take(letter_size) #=> Removes nested arrays and takes letters e.g. ["Z", "J", "S", "G"]
  end


  # Uses the Wagon Dictionary API and checks for validity
  def valid_word?(word)
    url = "https://wagon-dictionary.herokuapp.com/#{word}" #=> Le Wagon API
    url_serialized = URI.open(url).read #=> returns string of API e.g. "{\"found\":true,\"word\":\"banana\",\"length\":6}"
    word = JSON.parse(url_serialized) #=> returns hash e.g. {"found"=>true, "word"=>"banana", "length"=>6}
    word['found'] #=> returns true or false
  end

  def list_duplicates(word)
    # binding.pry
    splitted_word = @word.downcase.chars
    splitted_word.select { |e| splitted_word.count(e) > 1 } #=> ("spell") => ["l", "l"]
  end

  def chars_by_occurence(char_duplicates)
    char_duplicates.group_by { |i| i }.map { |k, v| [k, v.count] }.to_h #=> e.g. {"e"=>2, "l"=>2, "o"=>2}
  end

  def word_in_letters?(word, letters)
    sorted_letters = letters.downcase.chars.sort.reverse #=> e.g. ["s", "p", "o", "o", "o", "o", "l", "e"]
    sorted_word = word.downcase.chars.sort.reverse #=> possible subset of sorted_grid e.g. ["s", "p", "l", "l", "l", "e"]
    subset = sorted_letters - sorted_word #=> ["o", "o", "o", "o"]

    duplicates_word = list_duplicates(word) #=> ["l", "l", "l"]
    duplicates_letters = list_duplicates(letters.chars) #=> ["o", "o", "o", "o"]

    intersection = duplicates_letters & duplicates_word #=> [ ] or with intersection e.g. ["o"]

    word_chars_duplicates = chars_by_occurence(duplicates_word)
    letters_chars_duplicates = chars_by_occurence(duplicates_letters)

    exceeded_letters = intersection.empty? ? intersection.empty? && duplicates_word.empty? : letters_chars_duplicates[intersection.first] > word_chars_duplicates[intersection.first]

    # returns true if subset is < sorted_grid (sample size), all chars are included in sorted_grid and no exceeded letters
    subset.length < sorted_letters.length && sorted_word.all? { |char| sorted_letters.include?(char) } && exceeded_letters
  end

  def measure_time(start_time, end_time)
    end_time - start_time
  end

  def calc_score(word, letters, start_time, end_time)
    time_score = measure_time(start_time, end_time)
    # Gives points when valid_word? and word_in_grid? both true
    word_score = valid_word?(word) && word_in_letters?(word, letters) ? word.length * 100 : 0
    if word_score.positive?
      word_score - time_score if (word_score - time_score).positive? #=> additional loop ensures word_score > 0
    else
      0
    end
  end

  def select_message(word, letters)
    if valid_word?(word) && word_in_letters?(word, letters)
      "Well done! #{@word.upcase} is a valid English word!"
    elsif valid_word?(word) && !word_in_letters?(word, letters)
      "Sorry but #{@word.upcase} can't be built out of #{@letters}"
    elsif !valid_word?(word) && word_in_letters?(word, letters)
      "Sorry but #{@word.upcase} does not seem to be a valid English word..."
    else
      "Try again!"
    end
  end

  def run_game(word, letters, start_time, end_time)
    time = measure_time(start_time, end_time)

    score = calc_score(word, letters, start_time, end_time) #=> combination of time + word length valid and in grid
    message = select_message(word, letters)
    {
      time: time,
      score: score,
      message: message
    }
  end
end
