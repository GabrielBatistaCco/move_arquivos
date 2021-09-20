#!/bin/bash

# Script By: Gabriel Souza
# OBS: Script dedicado a movimentacao automatizada de uma grande lista de arquivos.

# Instruções de uso:
# Substitua as variaveis "DIR_SRC" e "DIR_DST" para execucoa automatica (linhas: 11 e 12)
# ou comente-as e descomente a chamada da funcao "entrada_diretorios" (linha: 104)
# para selecao dos diretorios durante a execucao.

DIR_SRC="/var/www/arquivos";
DIR_DST="/mnt/teste";

ROOT="/root/move_arquivos";
LISTA_SRC='/root/move_arquivos/lista_arquivos.txt';
LISTA_DIR_SRC='/root/move_arquivos/lista_diretorios.txt';
LISTA_F='/root/move_arquivos/lista_falhas.txt';

LOG='/var/log/move_arquivos.log';

COUNT_S=0;
COUNT_F=0;

RED='\033[0;31m'
GREEN='\033[0;32m';
NC='\033[0m' # Reset cor

#Barra de progresso
declare -r BAR_SIZE="######################################################################"
declare -r MAX_BAR_SIZE=${#BAR_SIZE}

trap killgroup SIGINT

killgroup(){
  echo "Script abortado..."
  tput cnorm -- normal
  exit 0
}

function entrada_diretorios {
  FALHA_DIR=1;
  while [ $FALHA_DIR -gt 0 ]
  do
    if [ $FALHA_DIR -eq 3 ]
    then
      read -p "Diretório destino:" DIR_DST;
      DIR_DST=${DIR_DST%/};
    elif [ $FALHA_DIR -eq 2 ]
    then
      read -p "Diretório origem:" DIR_SRC;
      DIR_SRC=${DIR_SRC%/};
    elif [ $FALHA_DIR -eq 1 ]
    then
      read -p "Diretório origem:" DIR_SRC;
      DIR_SRC=${DIR_SRC%/};
      read -p "Diretório destino:" DIR_DST;
      DIR_DST=${DIR_DST%/};
    fi

    if [ ! -d $DIR_SRC ] && [ ! -d $DIR_DST ]
    then
      echo ""; echo "Diretorios informados não existem, favor inserir diretorios validos!"; echo "";
      FALHA_DIR=1;
    elif [ ! -d $DIR_SRC ]
    then
      echo ""; echo "Diretorio origem não existe, favor inserir um diretorio valido!"; echo "";
      FALHA_DIR=2;
    elif [ ! -d $DIR_DST ]
    then
      echo ""; echo "Diretorio destino não existe, favor inserir um diretorio valido!"; echo "";
      FALHA_DIR=3;
    else
      FALHA_DIR=0;
    fi
  done
  echo ""; echo "##========================================================##";
}

function valida_movimentacao {
  if [ $? -eq 0 ]
  then
    if [ `ls -d1 $DIR_DST/$1 2>/dev/null | wc -l` -eq 1 ]
    then
      echo -e "$(date "+%d/%m/%Y %H:%M:%S") - $1 ${GREEN}(sucesso)${NC}" >> $LOG;
      rm $DIR_SRC/$1 -r 2>/dev/null;
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
  echo -ne "\\r[${BAR_SIZE:0:PROG_BAR}] $PROG % - $QTD/$QTD_TOTAL";
}

#entrada_diretorios;

tput civis -- invisible

echo "###======== Inicio execucao $(date "+%d/%m/%Y %H:%M:%S") ========###" >> $LOG;

DIR_SRC=${DIR_SRC%/};
DIR_DST=${DIR_DST%/};

if [ ! -d "$ROOT" ]
then
  mkdir $ROOT;
fi

echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - Listando arquivos e diretorios a serem movidos..." >> $LOG;
echo ""; echo "Listando arquivos e diretorios a serem movidos...";

ls -1 $DIR_SRC > $LISTA_SRC;
ls -d1 $DIR_SRC/*/ | awk -F "$DIR_SRC/" {'print $2'} > $LISTA_DIR_SRC;

echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - Verificando arquivos e diretorios..." >> $LOG;
echo ""; echo "Verificando arquivos e diretorios...";

sed -i 's/\/$//' $LISTA_DIR_SRC;

QTD_TOTAL=`cat $LISTA_SRC | wc -l`;

while IFS= read -r linha || [[ -n "$linha" ]]; do
  sed -i "/$linha/d" $LISTA_SRC;
done < "$LISTA_DIR_SRC"

QTD_ARQUIVOS=`cat $LISTA_SRC | wc -l`;
QTD_DIR=`cat $LISTA_DIR_SRC | wc -l`;

echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - $QTD_TOTAL verificados, sendo $QTD_ARQUIVOS arquivos e $QTD_DIR diretorios" >> $LOG;

echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - Movendo arquivos de $DIR_SRC/ para $DIR_DST/..." >> $LOG; echo "" >> $LOG;
echo ""; echo "Movendo arquivos de $DIR_SRC/ para $DIR_DST/..."; echo "";

echo "Arquivos nao encontrados:" >> $LISTA_F; echo "" >> $LISTA_F;
while IFS= read -r linha || [[ -n "$linha" ]]; do
  cp $DIR_SRC/$linha $DIR_DST 2>/dev/null;
  valida_movimentacao $linha;
done < "$LISTA_SRC"

echo "" >> $LOG; echo "$(date "+%d/%m/%Y %H:%M:%S") - Movendo diretorios de $DIR_SRC/ para $DIR_DST/..." >> $LOG; echo "" >> $LOG;

echo "" >> $LISTA_F; echo "Diretorios nao encontrados:" >> $LISTA_F; echo "" >> $LISTA_F;
while IFS= read -r linha || [[ -n "$linha" ]]; do
  cp $DIR_SRC/$linha $DIR_DST/ -r 2>/dev/null;
  valida_movimentacao $linha;
done < "$LISTA_DIR_SRC"

tput cnorm -- normal

echo "" >> $LOG; echo "Resumo:" >> $LOG; echo "" >> $LOG;
echo "TOTAL = $QTD_TOTAL" >> $LOG;
echo "SUCESSO = $COUNT_S" >> $LOG;
echo "FALHAS = $COUNT_F" >> $LOG;

echo ""; echo ""; echo "FIM DA EXECUCAO DO SCRIPT!";

echo ""; echo "Resumo:"; echo "";
echo "TOTAL = $QTD_TOTAL";
echo "SUCESSO = $COUNT_S";
echo "FALHAS = $COUNT_F";
echo ""; echo 'Para mais detalhes da execucao do script, consulte a lista '$LOG'!';
echo "As listas de arquivos e diretorios movidos estao em $ROOT/"; echo "";

if [ $COUNT_F -gt 0 ]
then
  echo -e "${RED}!!! SCRIPT EXECUTADO COM FALHA !!!${NC}";
  echo "Verifique a lista de falhas em: $LISTA_F.";
else
  rm $LISTA_F;
  echo -e "${GREEN}!!! SCRIPT EXECUTADO COM SUCESSO !!!${NC}";
  echo "Todos os arquivos e diretorios foram movidos e validados!";
fi

echo "" >> $LOG; echo "###======== Fim da execucao $(date "+%d/%m/%Y %H:%M:%S") ========###" >> $LOG; echo "" >> $LOG;
echo "";
