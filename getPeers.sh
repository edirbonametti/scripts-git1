#!/bin/bash
#===========================
# @author Edir Bonometti
# @since 2023-02-21
# @version 1.0
#==========================

# Le o arquivo ramais.txt
peers=($(<ramais.txt))

# Roda em todos os peers no array 
for peer in "${peers[@]}"; do
  # Coleta username e agent para cada peer
 # output=$(sudo docker exec -i <SeuContainer> asterisk -rx "sip show peer $peer" | grep -E "Username|Useragent" | awk '{ print $1; print $3; print $5}')
  output=$(sudo docker exec -i <SeuContainer> asterisk -rx "sip show peer $peer" | grep -E "Username|Useragent")

  # Escreve o resultado para cada peer encontrado no arquivo sip_results.txt
  echo "Results for peer $peer:" >> sip_results.txt
  echo "$output" >> sip_results.txt
done
