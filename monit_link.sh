#!/bin/bash
#==============================================================
# @author Edir Bonametti
# @since 2023-31-03
# @version 1.0
# Description: Daemon do script link_redundante
# process name: link_redundante
#==============================================================
# Source function library.
. /etc/init.d/functions

# Verifica se o arquivo de configuração existe

[ -f /etc/init.d/link_redundante ] || exit 0

# Comando utilizado para rodar o script de monitoramento
COMMAND="/etc/init.d/link_redundante"

RETVAL=0

# função para pegar o PID do processo.
getpid() {
    pid=`ps -eo pid,comm | grep link_redundante | awk '{ print $1 }'`
}

# Função para iniciar o script link_redundate
start() {
    echo  $"Iniciando o Monitoramento de LINK: "
    getpid
    if [ -z "$pid" ]; then
        rm -rf /var/run/link_redundate.sock # Caso o processo já exista limpa o sock
# Inicializa o monitoramento no intervalo de 10 segundos
        $COMMAND monitor 10 & > /dev/null
        RETVAL=$?
    fi
# Se o retorno do comando anterior for verdadeiro, cria o arquivo link_redundate
    if [ $RETVAL -eq 0 ]; then
        touch /var/lock/subsys/link_redundante
        echo_success
    else
# Caso retorne falso
        echo_falhou
    fi
    echo
#    return $RETVAL
}
# Função que para o monitoramento'
stop() {
    echo  $"Parando Monitoramento do LINK: "
    getpid
    RETVAL=$?
    if [ -n "$pid" ]; then
        $COMMAND link1 > /dev/null
        kill -9 $pid
    sleep 2
    getpid
    if [ -z "$pid" ]; then
        rm -f /var/lock/subsys/link_redundante
        echo_success
    else
        echo_failure
    fi
    else
        echo_failure
    fi
    echo
   return $RETVAL
}

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        getpid
        if [ -n "$pid" ]; then
                echo "Monitoramento de link (PID $pid) está Rodando...."
                $COMMAND status
        else
                RETVAL=1
                echo "Monitoramento de link está parado...."
        fi
        ;;
  restart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac

exit $RETVAL