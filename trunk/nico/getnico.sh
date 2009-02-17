#!/bin/bash
#Ver 0.20090217
#Usage:
#getnico "$URL"
#switches:
#	"-t"	download Taiwan's subtitles
#	"-j"	download Japan's subtitles

UserAgent="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.12) Gecko/20080207 Ubuntu/7.10 (gutsy) Firefox/2.0.0.12"

NormalizeURL(){
	input_url=`echo $input_url|sed 's/%3A/:/g'|sed 's/%2F/\//g'|sed 's/%3F/?/g'|sed 's/%3D/=/g'`
}

GetSub(){
	case $language in
		jap);;
		chi)
			v_value=`wget -q --no-check-certificate --load-cookies cookies.txt --keep-session-cookies --save-cookies cookies.txt -O - \
				  --user-agent="$UserAgent" \
				  "http://tw.nicovideo.jp/watch/"$NicoID | 
				grep "var Video" -A2|grep "v:"|cut -d"'" -f2`

			Info_URL=`wget -q "http://tw.nicovideo.jp/api/getflv?v="$v_value \
				  --load-cookies cookies.txt \
				  --user-agent="$UserAgent" \
				  -O /dev/stdout`
			PhaseAPI;;
	esac

	post_data="<thread res_from=\"-500\" version=\"20061206\" thread=\""$thread_id"\" />"
	wget $ms \
		  --load-cookies cookies.txt \
		  --user-agent="$UserAgent" \
		  --post-data "$post_data"\
		  -O "$filename$LowFlag.$language.xml"
}

Login(){
	read -p "E-mail:" Email
	read -p "Password: " -s Password

	Sumit="next_url=&mail="`echo $Email|sed 's/\@/%40/g'`"&password="$Password"&submit.x=0&submit.y=0"

	wget --no-check-certificate  --keep-session-cookies --save-cookies cookies.txt -q -O /dev/null \
		  --user-agent="$UserAgent" \
		  --post-data "$Sumit"\
		  "https://secure.nicovideo.jp/secure/login?site=niconico"
}

#phase api information
PhaseAPI(){
	for i in $( echo $Info_URL|sed 's/&/ /g' );do
		patten=( `echo $i|sed 's/=/ /g'`)
		case ${patten[0]} in
			thread_id)
				thread_id=${patten[1]}
			;;
			url)
				input_url=${patten[1]}
				NormalizeURL
				url=$input_url
				file_flag=`echo $url|cut -d'?' -f2|cut -d'=' -f1`
			;;
			ms)
				input_url=${patten[1]}
				NormalizeURL
				ms=$input_url
			;;
		esac
	done
}

for i in $@;do
	case $i in
		-t)taiwan_sub_flag=1;;
		-j)japan_sub_flag=1;;
		*)nico_url=$i;;
	esac
done

#nico_url=`gdialog --title "Nico下載工具" --inputbox "請輸入Nico網址:" 2>&1`
#if [ ! `echo $nico_url` ];then exit ;fi

nico_url=$1

NicoID=`echo $nico_url | perl -pe 's/.*nicovideo\.jp\/watch\/(.+)/$1/g'`

##cookie
if [ -f ~/.mozilla/firefox/`ls ~/.mozilla/firefox/ | grep default`/cookies.sqlite ] ; then

	sqlite3 -list -separator '	' ~/.mozilla/firefox/`ls ~/.mozilla/firefox/ | grep default`/cookies.sqlite \
	"SELECT host, path, expiry, name, value 
	FROM moz_cookies 
	WHERE host like '%.nicovideo.jp'"\
	|perl -pe 's/(.*)\t(.*)\t(.*\t.*\t)/$1\tTRUE\t$2\tFALSE\t$3/'>cookies.txt
else
	cat ~/.mozilla/firefox/`ls ~/.mozilla/firefox/ | grep default`/cookies.txt| grep .nicovideo.jp > cookies.txt
fi

if [ -f cookies.txt ] ; then
	LoginFlag=`wget -q "http://www.nicovideo.jp/" \
		  --load-cookies cookies.txt \
		  --user-agent="$UserAgent" \
		  -O /dev/stdout| \
		  grep "http://res.nicovideo.jp/img/login_form/btn_login.gif"`

	if [ ! -z $LoginFlag ];then Login ;fi
else
	Login
fi

#download video page and phase the video name
origional_name=`wget -q --no-check-certificate --load-cookies cookies.txt --keep-session-cookies --save-cookies cookies.txt -O - \
	  --user-agent="$UserAgent" \
	  "http://www.nicovideo.jp/watch/"$NicoID|
	grep \<title\>|perl -pe 's;<title>(.+)‐ニコニコ動画\(.+\)</title>.*;$1;g'`

Info_URL=`wget -q "http://www.nicovideo.jp/api/getflv?v="$NicoID \
	  --load-cookies cookies.txt \
	  --user-agent="$UserAgent" \
	  -O /dev/stdout`

PhaseAPI

case $file_flag in
	v)file_type="flv";;
	m)file_type="mp4";;
esac

if [ `echo $url | grep low` ] ;then
	LowFlag=[low]
	#echo "由於NICO伺服器忙碌，現在只能載到低畫質版本的該影片"
	echo "Since NICO server is busy now，you can only download low quality version of this video"
fi

if [ -f "$filename$LowFlag.$file_type" ] ; then conti_flag="-c" ;fi

wget $url \
          --load-cookies cookies.txt \
          --user-agent="$UserAgent" $conti_flag\
          -O "[$NicoID]$LowFlag$origional_name.$file_type"

if [ `echo $japan_sub_flag` ];then language="jap";GetSub ;fi
if [ `echo $taiwan_sub_flag` ];then language="chi";GetSub ;fi

rm cookies.txt
