#This script may help for you using the scripts: msn.php,msnaccount.php, split.rb
#
#I puts my chat logs into different folders named by when I archived them.
#Therefore, the variable name, $date, may not reasonable for you.
#-------------------
#供參考我如何使用那幾個script: msn.php,msnaccount.php, split.rb
#
#Author：Shenk @ [PTT BBS in Taiwan]
#Blog：http://blog.pixnet.net/Shenk

date=$1
script_path="/path/to/scripts"
log_path="/path/to/logs/"$date

msn_convert=$script_path"/msn.phs"
msn_account=$script_path"/msnaccount.phs"
spliter=$script_path"/split.rb"

count=1

for i in $(ls "$log_path");do
	count=$((count+1))
	#Change title format whatever you like
	title="[Tag]以msn對"`"$msn_account" $i`"在"$date"之前的聊天紀錄"
	echo \"$msn_convert\" \"$log_path/$i\"\|\"$spliter\"" "$title" 2>>"$date".log"|bash
	echo $i"...OK"
	echo $i"...OK" >> $date.log
done

