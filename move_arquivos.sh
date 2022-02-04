#!/bin/bash

# By: Gabriel Souza
# Script para movimentacao de uma grande lista de arquivos/diretorios de uma forma mais segura e auditavel.

DIR_SRC=${1%/};
DIR_DST=${2%/};

ROOT=`pwd`;
LISTA_SRC="$ROOT/listas/lista_arquivos.txt";
LISTA_DIR_SRC="$ROOT/listas/lista_diretorios.txt";
LOG_F="$ROOT/listas/falhas.txt";
LOG='/var/log/move_arquivos.log';

COUNT_S=0;
COUNT_F=0;

RED='\033[0;31m'
GREEN='\033[0;32m';
NC='\033[0m' # Reset cor

function print_separador {
  echo ""; echo "##===========================================================================##";
}

function barra_progresso {
  BAR_SIZE="#####################################################"
  MAX_BAR_SIZE=${#BAR_SIZE}

  let QTD=$COUNT_S+$COUNT_F;
  let PROG=($QTD*100)/$QTD_TOTAL;
  let PROG_BAR=($PROG*$MAX_BAR_SIZE)/100;
  echo -ne "\\rProgresso: [${BAR_SIZE:0:PROG_BAR}] $PROG % - $QTD/$QTD_TOTAL";
}

function log {
  case $1 in
    0)
      echo -e "$2" >> $LOG;
      echo -e "$2";
      ;;
    00)
      echo -e "$2" >> $LOG; echo "" >> $LOG;
      echo -e "$2"; echo "";
      ;;
    1)
      echo -e "$(date "+%d/%m/%Y %H:%M:%S") --> $2" >> $LOG;
      ;;
    10)
      echo -e "$2" >> $LOG; echo "" >> $LOG;
    ;;
    2)
      echo -e "$(date "+%d/%m/%Y %H:%M:%S") --> $2" >> $LOG;
      echo -e "$2";
      ;;
    S)
      echo "$2";
    ;;
    *)
      echo "";
  esac
}

function gera_listas {

  mkdir -p "$ROOT/listas/";

  log 00 "Listando arquivos e diretorios a serem movidos...";
  ls -1 $DIR_SRC > $LISTA_SRC;
  ls -d1 $DIR_SRC/*/ 2>/dev/null | awk -F "$DIR_SRC/" {'print $2'} > $LISTA_DIR_SRC;
  log 00 "Listas criadas em $ROOT/";
}

function valida_movimentacao {
  if [ $? -eq 0 ]
  then
    if [ `ls -d1 $DIR_DST/"$1" 2>/dev/null | wc -l` -eq 1 ]
    then
      log 1 "$1 ${GREEN}(sucesso)${NC}";
      rm $DIR_SRC/"$1" -r 2>/dev/null;
      let COUNT_S++;
    else
      log 1 "$1 ${RED}(nao encontrado)${NC}";
      echo "  $1" >> $LOG_F;
      let COUNT_F++;
    fi;
  else
    log 1 "$1 ${RED}(falha ao copiar)${NC}";
    echo "  $1" >> $LOG_F;
    let COUNT_F++;
  fi

  barra_progresso;
}

function calcula_tempo {
  HORA=$(date +%H); let HORA=${HORA#0}*60*60;
  MINUTO=$(date +%M); let MINUTO=${MINUTO#0}*60;
  SEGUNDO=$(date +%S); SEGUNDO=${SEGUNDO#0};
  let TEMPO=$HORA+$MINUTO+$SEGUNDO;

  if [ -z $1 ]; then
    echo $TEMPO;
  else
    let TEMPO=$TEMPO-$1;
    let HORA=$TEMPO/3600;
    let MINUTO=($TEMPO-$HORA*3600)/60;
    let SEGUNDO=$TEMPO%60;
    echo "$HORA"h":$MINUTO"m":$SEGUNDO"s"";
  fi
}

function resumo_execucao {
  log 0; log 00 "RESUMO DA EXECUCAO:";
  log 0 "  Arquivos: $QTD_DIR";
  log 00 "  Diretórios: $QTD_ARQUIVOS";
  log 0 "  TOTAL = $QTD_TOTAL";
  log 0 "  SUCESSO = $COUNT_S";
  log 00 "  FALHAS = $COUNT_F";
  log 00 "  Tempo: $TEMPO"
  log S "Consulte: $LOG' para mais detalhes!";
}

if [[ ! -d $DIR_SRC && ! -d $DIR_DST ]] || [[ -z $DIR_SRC && -z $DIR_DST ]]
then
  echo ""; echo "Diretorios informados não encontrados, favor inserir diretorios validos!"; echo "";
  exit 0;
elif [ $DIR_SRC == $DIR_DST ]
then
  echo ""; echo "Diretorio de origem nao pode ser o mesmo de destino, favor inserir diretorios validos!"; echo "";
  exit 0;
elif [ ! -d $DIR_SRC ] || [ -z $DIR_SRC ]
then
  echo ""; echo "Diretorio origem não encontrado, favor inserir um diretorio valido!"; echo "";
  exit 0;
elif [ ! -d $DIR_DST ] || [ -z $DIR_DST ]
then
  echo ""; echo "Diretorio destino não encontrado, favor inserir um diretorio valido!"; echo "";
  exit 0;
else
  echo "##================== Execucao iniciada $(date "+%d/%m/%Y %H:%M:%S") ==================##" >> $LOG; echo "" >> $LOG;
  INICIO=`calcula_tempo`;

  print_separador;

  if [ ! -e $LISTA_SRC ] && [ ! -e $LISTA_DIR_SRC ]; then
    gera_listas;
  else
    echo ""; read -p "Ja existe arquivo de lista pre-configurado, deseja usa-lo[s/n]? " OP; echo "";
    case $OP in
      (s|S)
        log 10 "Usar lista pre-configurada: $OP";
        if [ ! -e $LISTA_DIR_SRC ]; then
          >$LISTA_DIR_SRC;
        elif [ ! -e $LISTA_SRC ]; then
          >$LISTA_SRC;
        fi
      ;;
      (n|N)
        log 10 "Usar lista pre-configurada: $OP";
        gera_listas;
      ;;
      (*) log 00 "Opcao Invalida! Abortado!"; exit 0 ;;
    esac
  fi

  log 00 "Verificando listas...";

  sed -i 's/\/$//' $LISTA_DIR_SRC;

  QTD_DIR=`cat $LISTA_DIR_SRC | egrep [a-zA-Z0-9] | wc -l`;

  if [ $QTD_DIR -gt 0 ]; then
    while IFS= read -r linha || [[ -n "$linha" ]]; do
      sed -i "/$linha/d" $LISTA_SRC;
    done < "$LISTA_DIR_SRC"
  fi

  QTD_ARQUIVOS=`cat $LISTA_SRC | egrep [a-zA-Z0-9] | wc -l`;
  let QTD_TOTAL=$QTD_ARQUIVOS+$QTD_DIR;

  if [ $QTD_TOTAL -gt 0 ]; then

    log 00 "Iniciando movimentação de $DIR_SRC/ para $DIR_DST/...";

    echo "RESUMO DE FALHAS:" > $LOG_F; echo "" >> $LOG_F;
    echo "Arquivos:" >> $LOG_F; echo "" >> $LOG_F;

    if [ $QTD_ARQUIVOS -gt 0 ]; then
      while IFS= read -r linha || [[ -n "$linha" ]]; do
        cp $DIR_SRC/"$linha" $DIR_DST 2>/dev/null;
        valida_movimentacao "$linha";
      done < "$LISTA_SRC"
    fi

    echo "" >> $LOG_F; echo "Diretorios:" >> $LOG_F; echo "" >> $LOG_F;

    if [ $QTD_DIR -gt 0 ]; then
      while IFS= read -r linha || [[ -n "$linha" ]]; do
        cp -r $DIR_SRC/"$linha" $DIR_DST/ 2>/dev/null;
        valida_movimentacao "$linha";
      done < "$LISTA_DIR_SRC"
    fi

    TEMPO=`calcula_tempo $INICIO`;

    echo "";
    log 0 "`print_separador`";

    if [ $COUNT_F -gt 0 ]
    then
      log 0; log 0 "                    ${RED}!!! SCRIPT EXECUTADO COM FALHA !!!${NC}";
      resumo_execucao;
        echo "`cat $LOG_F`" >> $LOG; echo "" >> $LOG;
      print_separador;
    else
      rm $LOG_F;
      log 0; log 0 "                    ${GREEN}!!! SCRIPT EXECUTADO COM SUCESSO !!!${NC}";
      resumo_execucao;
      print_separador;
    fi
  else
    log 0 "Listas para movimentacao estao vazias, execucao finalizada!";
    print_separador;
  fi
  echo "##================= Execucao finalizada $(date "+%d/%m/%Y %H:%M:%S") =================##" >> $LOG; echo "" >> $LOG;
fi
exit 0;
