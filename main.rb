require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

helpers do
  def calculate_total(cards)
    # [['hearts', '2'], ['spades', 'jack'], ...]
    total = 0
    faces = cards.map { |e| e[1] }

    faces.each do |face|
      if face == "ace"
        total += 11
      elsif face.to_i == 0 # jack, queen, king
        total += 10
      else
        total += face.to_i
      end
    end

    # correct for aces
    faces.select { |e| e == "ace" }.count.times do
      total -= 10 if total > BLACKJACK_AMOUNT
    end

    total
  end

  def card_image(card)
    # ['hearts', '2'], ['spades', 'jack'], ...
    "<img src='/images/cards/#{card[1]}_of_#{card[0]}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>#{session[:player_name]} win!</strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @error = "<strong>#{session[:player_name]} lose!</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>It's a tie!</strong> #{msg}"
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:player_name]
    redirect "/game"
  else
    redirect "/new_player"
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required."
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name].downcase.capitalize
  redirect '/game'
end

get '/game' do
  session[:turn] = session[:player_name]

  suits = ['hearts', 'diamonds', 'spades', 'clubs']
  cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'jack', 'queen', 'king', 'ace']

  session[:deck] = suits.product(cards).shuffle!

  # Deal Cards: 
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop

  dealer_total = calculate_total(session[:dealer_cards])
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} has hit blackjack.")
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} has hit blackjack.")
  elsif player_total > BLACKJACK_AMOUNT
    loser!("#{session[:player_name]} busted at #{player_total}.")
  end

  erb :game
end

post '/game/player/stay' do
  @info = "You choose stay! You total is #{calculate_total(session[:player_cards])}"
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer has hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}")
  elsif dealer_total >= DEALER_MIN_HIT # stay
    redirect '/game/compare'
  else # auto hit
    # redirect '/game/dealer/hit'
    @show_dealer_hit_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  if player_total > dealer_total
    winner!("#{session[:player_name]}'s total is #{player_total} and dealer's total is #{dealer_total}.")
  elsif player_total < dealer_total
    loser!("#{session[:plyaer_name]}'s total is #{player_total} and dealer's total is #{dealer_total}.")
  else
    tie!("#{session[:player_name]} and dealer have equal totals of #{player_total}.")
  end

  erb :game
end

get '/game_over' do
  erb :game_over
end
