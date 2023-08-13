#!/bin/sh

OUT_FILE="config"

echo > ${OUT_FILE}
echo "[main]" >> ${OUT_FILE} 
echo "host = https://www.transifex.com" >> ${OUT_FILE}

echo "" >> ${OUT_FILE} 



for f in  $(find ../Radiola -path '*/en.lproj/*.strings'); do
    
    name=$(basename "${f}" ".strings")
    source_file=$f
    file_filter=${source_file/en.lproj/<lang>.lproj}:

    echo $name

    echo "[o:sokoloff:p:radiola:r:${name}]" >> ${OUT_FILE} 
    echo "source_file = ${source_file}" >> ${OUT_FILE} 
    echo "file_filter = ${file_filter}" >> ${OUT_FILE} 
    echo "source_lang = en" >> ${OUT_FILE} 
    echo "type        = STRINGS_UTF8" >> ${OUT_FILE} 
    echo "minimum_perc = 10" >> ${OUT_FILE} 
    echo "" >> ${OUT_FILE} 

done


