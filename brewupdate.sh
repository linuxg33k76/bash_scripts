#!/usr/bin/env bash

echo "Brew Update Script"

while true; {

        ask_question() {

        echo "Would you like to update brew? (Y/N)"
        read answer

        if [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "Yes" || "$answer" = "YES" ]]; then
                brew update && brew upgrade
                break
        elif [[ "$answer" == "n" || "$answer" == "N" || "$answer" == "no" || "$answer" == "No" || "$answer" = "NO" ]]; then
                echo "Proceeding without updating brew."
                break
        else
                echo "You did not provide an valid input."
                echo
        fi

        }


# Call Ask Question function
ask_question

}
