#===============================================================================
#!/bin/bash
#===============================================================================
# @author Edir Bonametti
# @since 2023-31-03
# @version 1.0
# Description: Este script foi desenvolvido com o intuito de monitorar o link
# de internet, e realizar a troca do gateway em caso de falha do link principal.
#===============================================================================
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Modo de Usar:
#
# Existe um daemon que roda e monitora esse script, o mesmo esta localizado em
#
# /etc/init.d/monitor_link  ( status, stop, start, restart)
#
# Esse daemon, executa a função monitor, que faz a verificação de estado de
# link a cada 10 segundos.
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Início do Script (Declaração das Variáveis)

# Verificação de qual gateway está ativado na tabela de roteamento.
GWUP=`ip route show | grep ^default | cut -d " " -f 3`

# Gateway Principal
GW1=<IP DO GATEWAY PRINCIPAL>

# Gateway backup
GW2=<IP DO GATEWAY SECUNDÁRIO>

#Interface da NET
INTNET=eth2

#Interface Embratel
INTEBT=eth3

# IP de teste de conexão
IPTESTE=8.8.8.8

# Arquivo de log
LOG=/var/log/redundancia.log

COMANDO=$1
TEMPO=$2

# Função que gera os logs
function log() {
        MSG="[`date`] $@"
        echo $MSG >> $LOG
}

# Função utilizada para testar a conectividade do link Principal (NET)
 function testa_NET () {
        route add $IPTESTE gw $GW1 # Adiciona rota para sair pelo link NET
        ping -I $INTNET $IPTESTE -c 10 -A > /dev/null # Pinga o IP de teste
        pingok=$? # Guarda o retorno do comando anterior.
        route del $IPTESTE gw $GW1 # Remove a rota do IP de teste
        [ $pingok -eq 0 ] && return 0 || return 1 # Retorna 0 se link NET OK OU 1 se Não OK
}
# Função para ativar o link 1 (NET)
function ativa_link1() {
        log "Iniciando link Principal..."
        add_GW_NET # Chama a funcao add_GW_NET
}
# Função que adiciona rota para GATEWAY (NET)
function add_GW_NET() {
        log "Removendo Rota da Embratel"
        route del default gw $GW2 # Remove rota para Embratel caso ela exista.
        log "Adicionando Rota para a NET"
        route add default gw $GW1 # Adiciona rota para NET
}
# Função que desativa link 1
function desativa_link1 () {
        #log "Removendo Rota da NET"
        route del default gw $GW1 # Remove gateway do link 1
}
# Função que ativa link 2
function ativa_link2() {
        desativa_link1 # Chama função desativa_link1
        route add default gw $GW2 # Adiciona rota para o link 2
 ping -I $INTEBT $IPTESTE -c 5 -A > /dev/null # Testa conectividade do link Embratel
        if [[ $? -eq 0 ]]; then # Retorna 0 se o link OK OU 1 SE NÃO OK
#       log "Link EMBRATEL  Ativo"
        return 0;
  fi
  return 1;
}
# Função que desativa link 2
function desativa_link2() {
#       log "Removendo Gateway da Embratel"
        route del default gw $GW2 # Remove Gateway da Embratel
        return 0;
        return 1;
}
# ATENÇÃO...!!! Função Principal do script, quaisquer alterações nessa função devem ser feitas com precaução,
# caso contrario poderá comprometer o funcionamento do mesmo.
function monitor() {
        while true # Enquanto as condições abaixo forem verdadeiras, ele vai executar.
        do
                #Busca o default gateway na tabela de rotas local
                 GWUP=`ip route show | grep ^default | cut -d " " -f 3`

                # Verifica se o gateway atual e a NET
                if [ $GWUP == $GW1 ]; then # Se essa condição for verdadeira...continua no IF, se não entra no ELSE
                        log "Gateway atual apontando para NET"
#                       log "Realizando verificacao de estado do LINK"

                        if( ! testa_NET); then # Se a função testa net retornar falha, entra IF
                                log "Link NET indisponivel, ativando Gateway da EMBRATEL"
                                if(ativa_link2); then # Se função ativa link  retornar OK, entra no if, caso der falha, entra no ELSE.
                                        log "Link EMBRATEL ativado com Sucesso"
                                else
                                        log "Problema ao ativar Gateway da Embratel"
                                fi
                        fi
                else
                        log "Gateway atual apontando para EMBRATEL" #
                        # Ativa rota NET se ela estiver disponível
                        if(testa_NET ); then # Se link NET voltou, desativa o link 2 (EMBRATEL)
                                log "Link NET  disponivel, desativando GATEWAY da EMBRATEL e retornando para da NET"
                                if( desativa_link2 ); then #
                                        ativa_link1
                                fi
                        fi
                fi
                sleep $TEMPO
        done
}
case "$1" in
        monitor)
                echo "`date` - Monitorando Link Principal: intervalo $TEMPO segs"
                monitor
                ;;
        status)
                if [ $GWUP == $GW2 ]; then
                        echo "Utilizando EMBRATEL"
                else
                        echo "Utilizando NET"
                fi
                ;;
        link1)
                if [ $GWUP == $GW2 ]; then
                        desativa_link2
                        ativa_link1
                else
                        echo "Link1 ja em uso"
                fi
                ;;
        link2)
                if [ $GWUP == $GW1 ]; then
                        ativa_link2
                else
                        echo "Link2 ja em uso"
                fi
                ;;
        *)
                echo $"Usage: $prog { monitor + segundos | link1 | link2 | status }"
                exit 1
                ;;
esac
exit $?