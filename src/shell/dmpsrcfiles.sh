#!/bin/qsh
# @Use : copy sources in source files in IFS
# qsh dmpsrcfiles.sh 

# Create folders to store sources.
cd ~
rm -R src/dump
mkdir src/dump
cd src/dump

# We search user libraries containing souce files. 
db2 "SELECT DISTINCT '#' || trim(DBXLIB) FROM QSYS.QADBXREF 
WHERE DBXTYP = 'S'
AND DBXLIB NOT LIKE 'Q%'" |
 
while read -r line; 
do 
 grep '^#' | folderToCrt=$(sed s/#//g);  
 mkdir $folderToCrt
done
echo "All folders created"     

# Create files with correct CCSID.
db2 "select '# touch -C 1208 ' || TRIM(DBXLIB) || '/' ||
      TRIM(table_partition) || TRIM(VALUE ('.' || LCASE(source_type), ''))
     FROM QSYS.QADBXREF 
join SYSIBM.SYSPARTITIONSTAT
on table_name = DBXFIL and table_schema = dbxlib
WHERE DBXTYP = 'S'
AND DBXLIB NOT LIKE 'Q%'" | 
while read -r line; 
do 
 grep '^#' | cpcmd=$(sed s/#//g); 
 eval "$cpcmd";
done; 
echo "Files created"   

    
# Copy source members in stream files.
db2 "select '# cat /QSYS.LIB/' || trim (DBXLIB) || '.LIB/' || trim (DBXFIL) || '.FILE/' ||
      TRIM(table_partition) || '.MBR > ' || TRIM(DBXLIB) || '/' ||
      TRIM(table_partition) || TRIM(VALUE ('.' || LCASE(source_type), ''))
     FROM QSYS.QADBXREF 
join SYSIBM.SYSPARTITIONSTAT
on table_name = DBXFIL and table_schema = dbxlib
WHERE DBXTYP = 'S'
AND DBXLIB NOT LIKE 'Q%'" | 
while read -r line; 
do 
 grep '^#' | cpcmd=$(sed s/#//g); 
 eval "$cpcmd";
done; 
echo "All sources copied to IFS folder src/dump"    
                                                            
cd ~
                                                            
