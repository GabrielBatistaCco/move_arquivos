#!/bin/bash

# By: Gabriel Souza
# Script para movimentacao de uma grande lista de arquivos/diretorios de uma forma mais segura e auditavel.

DIR_SRC=${1%/};
DIR_DST=${2%/};

ROOT=`pwd`;
LISTA_SRC="$ROOT/lista_arquivos.txt";
LISTA_DIR_SRC="$ROOT/lista_diretorios.txt";
LISTA_F="$ROOT/lista_falhas.txt";

LOG='/var/log/move_arquivos.log';

COUNT_S=0;
COUNT_F=0;

RED='\033[0;31m'
GREEN='\033[0;32m';
NC='\033[0m' # Reset cor

#Barra de progresso
BAR_SIZE="#####################################################"
MAX_BAR_SIZE=${#BAR_SIZE}

function print_separador {
  echo ""; echo "##==========================================================================##";
}

function valida_movimentacao {
  if [ $? -eq 0 ]
  then
    if [ `ls -d1 $DIR_DST/"$1" 2>/dev/null | wc -l` -eq 1 ]
    then
      echo -e "$(date "+%d/%m/%Y %H:%M:%S") - $1 ${GREEN}(sucesso)${NC}" >> $LOG;
      rm $DIR_SRC/"$1" -r 2>/dev/null;
      let COUNT_S++;
    else
      echo -e "$(date "+%d/%m/%Y %H:%M:%S") - $1 ${RED}(nao encontrado)${NC}" >> $LOG;
      echo "$1" >> $LISTA_F;
      let COUNT_F++;
    fi;
  else
    echo -e "$(date "+%d/%m/%Y %H:%M:%S") - $1 ${RED}(falha ao copiar)${NC}" >> $LOG;
    echo "$1" >> $LISTA_F;
    let COUNT_F++;
  fi

  let QTD=$COUNT_S+$COUNT_F;
  PROG=$(((QTD * 100) / $QTD_TOTAL));
  PROG_BAR=$((PROG * MAX_BAR_SIZE / 100));
  echo -ne "\\rProgresso: [${BAR_SIZE:0:PROG_BAR}] $PROG % - $QTD/$QTD_TOTAL";
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
  echo "###======== Inicio execucao $(date "+%d/%m/%Y %H:%M:%S") ========###" >> $LOG;

  print_separador;

  if [ ! -e $LISTA_SRC ] && [ ! -e $LISTA_DIR_SRC ]; then
    echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - Listando arquivos e diretorios a serem movidos..." >> $LOG;
    echo ""; echo "Nao existem listas para movimentacao! Gerando...";
    ls -1 $DIR_SRC > $LISTA_SRC;
    ls -d1 $DIR_SRC/*/ 2>/dev/null | awk -F "$DIR_SRC/" {'print $2'} > $LISTA_DIR_SRC;
    echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - Listas criadas em $ROOT/..." >> $LOG;
    echo ""; echo "Listas para movimentacao criadas em $ROOT/";
  else
    echo ""; echo "Ja existe pelo menos uma lista em $ROOT/! A movimentacao ocorrera com base nela";
    echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - Ja existe lista em $ROOT/..." >> $LOG;
    if [ ! -e $LISTA_DIR_SRC ]; then
      >$LISTA_DIR_SRC;
    elif [ ! -e $LISTA_SRC ]; then
      >$LISTA_SRC;
    fi
  fi

  echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - Verificando arquivos e diretorios..." >> $LOG;
  echo ""; echo "Verificando arquivos e diretorios...";

  sed -i 's/\/$//' $LISTA_DIR_SRC;

  QTD_ARQUIVOS=`cat $LISTA_SRC | egrep [a-zA-Z0-9] | wc -l`;
  QTD_DIR=`cat $LISTA_DIR_SRC | egrep [a-zA-Z0-9] | wc -l`;

  let QTD_TOTAL=$QTD_ARQUIVOS+$QTD_DIR;

  if [ $QTD_DIR -gt 0 ]; then
    while IFS= read -r linha || [[ -n "$linha" ]]; do
      sed -i "/$linha/d" $LISTA_SRC;
    done < "$LISTA_DIR_SRC"
  fi

  if [ $QTD_TOTAL -gt 0 ]; then

    echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - $QTD_TOTAL verificados, sendo $QTD_ARQUIVOS arquivos e $QTD_DIR diretorios" >> $LOG;

    echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - Movendo arquivos de $DIR_SRC/ para $DIR_DST/..." >> $LOG; echo "" >> $LOG;
    echo ""; echo "Movendo arquivos de $DIR_SRC/ para $DIR_DST/..."; echo "";

    echo "Arquivos nao encontrados:" >> $LISTA_F; echo "" >> $LISTA_F;

    if [ $QTD_ARQUIVOS -gt 0 ]; then
      while IFS= read -r linha || [[ -n "$linha" ]]; do
        cp $DIR_SRC/"$linha" $DIR_DST 2>/dev/null;
        valida_movimentacao "$linha";
      done < "$LISTA_SRC"
    fi

    echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - Movendo diretorios de $DIR_SRC/ para $DIR_DST/..." >> $LOG; echo "" >> $LOG;
    echo "" >> $LISTA_F; echo "Diretorios nao encontrados:" >> $LISTA_F; echo "" >> $LISTA_F;

    if [ $QTD_DIR -gt 0 ]; then
      while IFS= read -r linha || [[ -n "$linha" ]]; do
        cp $DIR_SRC/"$linha" $DIR_DST/ -r 2>/dev/null;
        valida_movimentacao "$linha";
      done < "$LISTA_DIR_SRC"
    fi

    echo "" >> $LOG; echo "Resumo:" >> $LOG; echo "" >> $LOG;
    echo "TOTAL = $QTD_TOTAL" >> $LOG;
    echo "SUCESSO = $COUNT_S" >> $LOG;
    echo "FALHAS = $COUNT_F" >> $LOG;
    echo ""; print_separador;

    echo ""; echo "Resumo da execucao:"; echo "";
    echo "TOTAL = $QTD_TOTAL";
    echo "SUCESSO = $COUNT_S";
    echo "FALHAS = $COUNT_F";
    print_separador;

    if [ $COUNT_F -gt 0 ]
    then
      echo ""; echo -e "${RED}!!! SCRIPT EXECUTADO COM FALHA !!!${NC}";
      echo "Verifique a lista de falhas em: $LISTA_F.";
    else
      rm $LISTA_F;
      echo ""; echo -e "${GREEN}!!! SCRIPT EXECUTADO COM SUCESSO !!!${NC}";
      echo "Todos os arquivos e diretorios foram movidos e validados!";
    fi
    echo ""; echo 'Para mais detalhes da execucao do script, consulte: '$LOG'!';
  else
    echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - Nenhum arquivo/diretorio encontrato em $DIR_SRC para mover!" >> $LOG;
    echo ""; echo "Nenhum arquivo/diretorio encontrato em $DIR_SRC para mover!";
    echo ""; echo "Finalizando execução!";
  fi

  echo "" >> $LOG; echo "###======== Fim da execucao $(date "+%d/%m/%Y %H:%M:%S") ========###" >> $LOG; echo "" >> $LOG;
  print_separador;
fi
exit 0;
