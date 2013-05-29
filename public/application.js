$(document).ready(function(){
  player_hit();
  player_stay();
  dealer_hit();
});

function player_hit() {
  $(document).on("click", "form#hit_form input", function(event){
    $.ajax({
      type: "POST",
      url: "/game/player/hit"
    }).done(function(msg){
      $("div#game").replaceWith(msg);
    });
    event.preventDefault();
  });
}

function player_stay() {
  $(document).on("click", "form#stay_form input", function(event){
    $.ajax({
      type: "POST",
      url: "/game/player/stay"
    }).done(function(msg){
      $("div#game").replaceWith(msg);
    });
    event.preventDefault();
  });
}

function dealer_hit() {
  $(document).on("click", "form#dealer_hit input", function(event){
    $.ajax({
      type: "POST",
      url: "/game/dealer/hit"
    }).done(function(msg){
      $("div#game").replaceWith(msg);
    });
    event.preventDefault();
  })
}

