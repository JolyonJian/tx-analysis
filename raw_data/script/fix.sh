rm -rf valid_contract
rm -rf invalid_contract

for file in ./contracts/*
do
   info=`wc -c $file`
   res=`echo $info|awk '{print $1}'`
   if [ "$res" != "0" ];then
       res=`grep "contract.*{" $file|wc -l|tr -d " "`
       if [ "$res" != "0" ];then
            echo "$res $info" >> valid_contract
        else
            echo "$res $info" >> invalid_contract

        fi
   fi
done