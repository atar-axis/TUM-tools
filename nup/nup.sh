SUFFIX=nuped

for entry in "."/*
do
  echo "processing $entry"
  
    if [[ ! -f "./nup/$entry" ]]; then
        pdfnup $entry --landscape --nup 2x2 --paper a4paper --scale 0.9 --offset '0cm -0.5cm' --outfile "./nup/$entry"
        echo "done"
    else
        echo "already exists"
    fi  
  
done


