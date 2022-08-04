rm -rf group_contract_list
prefix="./filter_contracts/"
contracts=($(ls $prefix|sort -n))
size=${#contracts[*]}
already_found_contracts=()
for ((i=0;i<1000;++i))
do

   src_file=$prefix${contracts[i]}
   src_file_row=`wc -l $src_file|awk '{print $1}'|tr -d " "`

   flag=0
   for found_contract in ${already_found_contracts[@]}
   do
       if [ "$src_file" == "$found_contract" ]; then
           echo "$src_file already found"
           flag=1
       fi
   done

   if [ $flag -eq 1 ];then
       continue
   fi

   if [ "$src_file_row" == "0" ];then
       continue
    fi

   similary_contracts=($src_file)
   for ((j=i+1;j<1000;++j))
   do
       dst_file=$prefix${contracts[j]}
       dst_file_row=`wc -l $dst_file|awk '{print $1}'|tr -d " "`

       if [ "$dst_file_row" == "0" ];then
         continue
       fi

       uncommon_row=`sdiff -l $dst_file $src_file | cat -n | grep -v -e '($'|wc -l|tr -d " "`
       total_row=$((src_file_row+dst_file_row))
       diff_rate=$((uncommon_row*100/total_row))
       if [ $diff_rate -le 40 ];then
          echo "$diff_rate $src_file $dst_file"
          similary_contracts+=("$dst_file:$diff_rate%")
          already_found_contracts+=($dst_file)
       fi
    done
    echo "${similary_contracts[*]}" >> group_contract_list
done
