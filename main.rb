require 'rubygems'
require 'sinatra'

set :sessions, true

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
      total -= 10 if total > 21
    end

    total
  end

  def card_image(card)
    # ['hearts', '2'], ['spades', 'jack'], ...
    "<img src='/images/cards/#{card[0]}_#{card[1]}.jpg'>"
  end
end

before do
  @show_hit_or_stay_buttons = true
  @show_dealer_cards = false
end

get '/' do
  if session.has_key?(:player_name)
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
  if player_total == 21
    @success = "Congratulations! You has hit blackjack. You win!"
    @show_hit_or_stay_buttons = false
    @show_dealer_cards = true
    @play_again = true
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == 21
    @success = "Congratulations! You has hit blackjack. You win!"
    @show_hit_or_stay_buttons = false
    @play_again = true
  elsif player_total > 21
    @error = "Sorry #{session[:player_name]}, you busted. You lose!"
    @show_hit_or_stay_buttons = false
    @play_again = true
  end

  erb :game
end

post '/game/player/stay' do
  @info = "You choose stay! You total is #{calculate_total(session[:player_cards])}"
  @show_hit_or_stay_buttons = false
  @show_dealer_cards = true
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_hit_or_stay_buttons = false
  @show_dealer_cards = true

  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == 21
    @error = "Sorry #{session[:player_name]}, dealer has hit blackjack. You lose!"
    @play_again = true
  elsif dealer_total > 21
    @success = "Congratulations, dealer has busted. You win!"
    @play_again = true
  elsif dealer_total >= 17 # stay
    redirect '/game/compare'
  else # auto hit
    redirect '/game/dealer/hit'
  end
  
  erb :game
end

get '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  @show_dealer_cards = true

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  if player_total > dealer_total
    @success = "Congratulations, you win! Your total is #{player_total} and Daler's total is #{dealer_total}."
    @play_again = true
  elsif player_total < dealer_total
    @error = "Sorry #{session[:player_name]}, you lose! Your total is #{player_total} and Dealer's total is #{dealer_total}."
    @play_again = true
  else
    @info = "Oh, you and dealer have equal totals of #{player_total}. It's tie!"
    @play_again = true
  end

  erb :game
end

get '/goodbay' do
  erb '<h3>Goodbye <%= session[:player_name] %>, thanks for playing!!!</h3>'
end
