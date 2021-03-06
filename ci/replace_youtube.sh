#!/bin/zsh
Rscript make_video_lists.R

while read vid; do
  # vid="nvpHtzuZggg BV1mt4y1Q7Ls" # FOR TESTING
  youtube_id=`echo $vid | awk '{print $1}'`
  bilibili_id=`echo $vid | awk '{print $2}'`
  
  echo "Looking for youtube $youtube_id"
  
  find .. -name '*ipynb' -type f -exec grep -l "YouTubeVideo(id=.${youtube_id}." {} \; > files_to_change
  # sed -i'.bak' 's/:/ /g' files_to_change
  # rm -f files_to_change.bak



  while read f2c; do
    echo "Found $youtube_id in $f2c"
    # fname=`head -1 files_to_change` # FOR TESTING 
    fname="$f2c"
    lineno=`grep -n "YouTubeVideo(id=.${youtube_id}." "$fname" | awk '{print $1}' | sed 's/://'` # Need to recompute lineno since it changed.
    
    # Figure out if this code cell has an import line.

    has_import=`grep -b5 "YouTubeVideo(id=.${youtube_id}." "$fname" | grep "from IPython"`
    if [[ -z "${has_import}" ]]; then
      startline=${lineno}
    else
      startline=`expr ${lineno} - 1`
    fi

    endline=`expr $lineno + 1`
    insertline=`expr $startline - 1`

    # save the files for later

    echo "$fname" >> files_to_reprocess.txt

    # # Delete the youtube lines
    sed -i.back_1 -e "${startline},${endline}d" "$fname"    
  
    # Make the bilibili text
    sed "s/BILIID/$bilibili_id/" bilibili_code > this_bilicode
       
    # Insert bilibili text 
    sed  -i.back_2 "${insertline}r this_bilicode" ${fname}

  done <files_to_change 

done <video_ids.txt

# Only need to rerun each notebook once!
cat files_to_reprocess.txt | sort | uniq > unique_files

while read f2p; do
   echo "Rerunning $f2p"
  jupyter nbconvert --to notebook --inplace --execute "$f2p"
done <unique_files

find .. -name '*back_1' -delete
find .. -name '*back_2' -delete
# rm -f files_to_reprocess.txt
rm -f this_bilicode
rm -f bilibili_ids.txt
rm -f youtube_ids.txt
rm -f files_to_change
rm -f video_ids.txt