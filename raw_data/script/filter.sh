for file in ./filter_contracts/*
do
    row=`grep -r $'\r' $file|wc -l|tr -d " "`
    if [ "$row" != "0" ];then
        echo "m file $file, row $row"
        tr -d $'\r' < $file > $file.new
        mv $file.new $file
    fi
done