<h2>Observações</h2>

Script em shell criado para automatizar a movimentação de uma lista de arquivos muito extensa.

Esse script irá copiar todos os arquivos/diretórios do diretório origem, para o diretório destino que desejar, fazendo uma validação simples da existencia do arquivo no diretório destino, seguido da remoção do arquivo no diretório origem. Tudo é movido individualmente, ou seja, será copiado, validado e removido um a um.

Leia o script antes de executa-lo, verifique se atende a sua demanda!

<h2>Instruções de uso</h2>

Baixe o script com:

<pre>
git clone https://github.com/GabrielBatistaCco/move_arquivos
cd move_arquivos/
</pre>

Dê permissão para execução:

<pre>chmod +x move_arquivos.sh</pre>

Após isso, basta executar o script informando os diretórios de origem e destino respectivamente:

<pre>
./move_arquivos.sh /diretorio/origem/ /diretorio/destino/
</pre>

OBS: A movimentação pode ser feita a partir de uma lista, se existirem arquivos com os seguintes nomes dentro do diretório do script:

<pre>
listas/lista_arquivos.txt
listas/lista_diretorios.txt
</pre>

Se quiser acompanhar ou analisar a execução, tudo estará sendo registrado em: /var/log/move_arquivos.log
