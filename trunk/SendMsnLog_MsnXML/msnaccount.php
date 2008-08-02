#!/usr/bin/php
<?php
#Purpose: Guess ID of chat log xml from filename.
#	Please change the value of $accounts by array of your friend's account.
#
#Usage: msnaccount.phs some.xml
#Output: some@account.address or unknown
#-----------------------------------------
#目的：顯示某xml可能是和哪個人聊天的紀錄
#	請先將$accounts這array裡面的改成你的好友清單中的帳號
#
#用法：msnaccount.php some.xml
#輸出：some@account.address or unknown
#
#作法：比對每個帳號誰跟這檔名的字串從頭一樣的部份的長度，取最長者
#
#Author：Shenk @ [PTT BBS in Taiwan]
#Blog：http://blog.pixnet.net/Shenk

$accounts=array("friends@your.account");

function similar($string_a, $string_b){
	$length=(strlen($string_a)<strlen($string_b))? strlen($string_a):strlen($string_b);
	
	$string_a=str_split($string_a);
	$string_b=str_split($string_b);
	
	for($i=0;$i<$length;$i++){
		if($string_a[$i]!=$string_b[$i])return $i;
	}
	
	return$length;
}

$scale=0;
$account="";

foreach($accounts as $sample){
	$sample_scale=similar($sample,$argv[1]);
//	echo $sample."\n";
	if($sample_scale>$scale){
		$scale=$sample_scale;
		$account=$sample;
	}
}

if($account!=""){
	echo $account;
}else{
	echo "unknown";
}
?>
