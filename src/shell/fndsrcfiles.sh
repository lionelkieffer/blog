#!/bin/qsh
# @Use : recherche dans les fichiers sources
# qsh fndsrcfiles.sh FTP resultats_recherche_FTP.txt 
rm $2 
touch -C 1208 $2
db2 "SELECT '#' X, '/QSYS.LIB/' concat trim(DBXLIB) concat '.LIB/' 
     concat trim(DBXFIL) concat '.FILE'      
     FROM QSYS.QADBXREF WHERE DBXTYP = 'S' 
     AND DBXFIL not in ('QFTPSRC', 'QMNUSRC')" | 
while read -r line; 
do 
 grep '^#' | S=$(sed s/#//g); 
 find $S -name '*.MBR' | xargs grep -l -y $1 >> $2;
done; 
echo "FIN DE RECHERCHE"                                                                   
