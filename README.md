<h2>Observações</h2>

Script em shell criado para automatizar a movimentação de uma lista de arquivos muito extensa.

Basicamente o script irá copiar arquivos/diretórios individualmente de um diretório origem, para um diretório destino que desejar, fazendo uma validação simples da existencia do arquivo no diretório destino, seguido da remoção do arquivo no diretório origem.

Aproveite e leia o script antes de executa-lo, verifique se atende a sua demanda, pois não me responsabilizo pela possível perda de arquivos!

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

E aguardar sua execução!
