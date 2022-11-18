#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess --tuples-only -c"
# USER GUESS GLOBAL VAR
USER_GUESS=""
GUESS_COUNT=0

echo -e "\nEnter your username:"
read USER

USER_LOGIN(){
  if [[ -z $1 ]]
   then 
    echo -e "\nYou didn't provide a valid username."
   else
    USER_RECORD=$($PSQL "SELECT * FROM users WHERE username = '$1'")
    if [[ -z $USER_RECORD ]]
      then 
        echo -e "\nWelcome, $(echo $USER | sed -E 's/^ *| *$//g')! It looks like this is your first time here."
        INSERT_NEW_USER=$($PSQL "INSERT INTO users(username) VALUES('$USER')")
        # lets play
        NUMBER_GAME $USER
      else
        echo "$USER_RECORD" | while read USER_ID BAR USERNAME BAR GAMES_PLAYED BAR BEST_GAME
          do
            echo -e "Welcome back, $(echo $USERNAME | sed -E 's/^ *| *$//g')! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
          done
        NUMBER_GAME $USER
    fi
  fi
}

NUMBER_GAME(){
  # LOG GAME PLAYED
  GAME_PLAYED=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE username = '$1'")
  # FETCH HIGH SCORE
  HIGH_SCORE=$($PSQL "SELECT best_game FROM users WHERE username = '$1'")
  # HOUSE'S NUMBER
  SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
  # USER INPUT TYPE CHECKING
  USER_GUESS_TYPE_CHECK INIT_GUESS
  # IF THERE'S A VALID GUESS, LET'S PLAY
  if [[ ! -z $USER_GUESS ]]
    then
    GUESS_THE_NUMBER $SECRET_NUMBER $USER_GUESS $GUESS_COUNT $HIGH_SCORE $1
  fi
}

USER_GUESS_TYPE_CHECK(){
  # INITIAL GUESS AND MESSAGE
  GUESS_COUNT=$((GUESS_COUNT+1))
  if [ "$1" == "INIT_GUESS" ]; then 
    # PLAYERS GUESS
    echo -e "\nGuess the secret number between 1 and 1000:"
    read USER_GUESS
    # VALIDATE GUESS
      if [[ $USER_GUESS =~ ^[0-9]+$ ]]
      # TYPE CHECK SUCCESS RETURN TO GAME
        then return 
        # WRONG TYPE DETECTED START OVER
        else USER_GUESS_TYPE_CHECK "WRONG_TYPE"
      fi
      # GUESS IS THE WRONG TYPE
    elif [ "$1" == "WRONG_TYPE" ]; then 
      # ERROR MESSAGE
      echo -e "That is not an integer, guess again:"
      read USER_GUESS
      if [[ $USER_GUESS =~ ^[0-9]+$ ]]
      # TYPE CHECK SUCCESS RETURN TO GAME
        then return
        # WRONG TYPE DETECTED START OVER
        else USER_GUESS_TYPE_CHECK "WRONG_TYPE"
      fi
      # USER MESSAGES HANDLED IN GUESS_THE_NUMBER FOR INPROGRESS GAMES
      # NO ECHO
    elif [ "$1" == "IN_PROGRESS" ]; then 
    # TYPE CHECK SUCCESS RETURN TO GAME
      read USER_GUESS
      if [[ $USER_GUESS =~ ^[0-9]+$ ]]
        then return 
        # WRONG TYPE DETECTED START OVER
        else USER_GUESS_TYPE_CHECK "WRONG_TYPE"
      fi
  fi

}

GUESS_THE_NUMBER(){
  if [[ $1 -lt $2 ]]
    then 
    # USER GUESS WAS TOO HIGH
      echo -e "It's lower than that, guess again:"
      # GUESS AGAIN/VALIDATE GUESS
      USER_GUESS_TYPE_CHECK "IN_PROGRESS"
      GUESS_THE_NUMBER $1 $USER_GUESS $(($3 + 1)) $4 $5
    elif [[ $1 -gt $2 ]]
      then
      # USER GUESS WAS TOO LOW
        echo -e "It's higher than that, guess again:"
        # GUESS AGAIN/VALIDATE GUESS
        USER_GUESS_TYPE_CHECK "IN_PROGRESS"
        GUESS_THE_NUMBER $1 $USER_GUESS $(($3 + 1)) $4 $5
    elif [[ $1 -eq $2 ]]
      then echo -e "\nYou guessed it in $(echo $GUESS_COUNT | sed -E 's/^ *| *$//g') tries. The secret number was $(echo $1 | sed -E 's/^ *| *$//g'). Nice job!"
        if [[ $GUESS_COUNT -lt $4 ]] || [[ $4 -eq 0 ]]
          then 
            # UPDATE HIGH SCORE IN DB
            SCORE_UPDATE=$($PSQL "UPDATE users SET best_game = $GUESS_COUNT WHERE username = '$5'")
        fi
  fi
}

USER_LOGIN $USER
