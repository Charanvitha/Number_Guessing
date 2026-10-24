#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

SECRET=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read -r USERNAME

USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_DATA ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  IFS="|" read -r GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

echo "Guess the secret number between 1 and 1000:"
GUESSES=0

while true
do
  read -r GUESS || [[ -n $GUESS ]] || exit
  if [[ ! $GUESS =~ ^[-+]?[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi
  GUESSES=$((GUESSES + 1))

  if [[ $GUESS == -* ]]
  then
    echo "It's higher than that, guess again:"
    continue
  fi

  DIGITS=${GUESS#+}
  DIGITS=$(echo "$DIGITS" | sed 's/^0*//')
  if [[ -z $DIGITS ]]
  then
    DIGITS=0
  fi

  if (( ${#DIGITS} > 6 ))
  then
    echo "It's lower than that, guess again:"
    continue
  fi

  if (( DIGITS == SECRET ))
  then
    break
  elif (( DIGITS > SECRET ))
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

$PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 1, $GUESSES) ON CONFLICT (username) DO UPDATE SET games_played = users.games_played + 1, best_game = LEAST(COALESCE(users.best_game, $GUESSES), $GUESSES)" > /dev/null

echo "You guessed it in $GUESSES tries. The secret number was $SECRET. Nice job!"
