#!/bin/bash


##################################################################################
# Warning:
#   must be installed: zenity, beep, enca, md5sum, wget, mplayer, espeak, lame, mp3info
#
# Warning:
#   in ubuntu, zenity may work incorrect
##################################################################################

#################### config ######################################################
DISPLAY=:0.0

cd -P "$( dirname "${BASH_SOURCE[0]}" )"

_zenity="/usr/bin/zenity"
timeout=10
use_google=true
use_cache=true
prefix=true

source ./mail

cache_dir="cache"

if ! [ -e $cache_dir ] ; then
        mkdir $cache_dir
	echo "*" > $cache_dir/.gitignore
fi

title=$1
text=$2
if [ -z $text ] ; then text=`date`; fi
text_to_play=$3

enc=$(echo "$text_to_play" | enca)
echo "enc: $enc"

if [ "$enc" == "7bit ASCII characters" ] ; then
    enc="en"
    if [ $prefix == true ] ; then prefix="Attention: "; fi
    if [ -z $title ] ; then title='Reminder'; fi
else
    enc="ru"
    if [ $prefix == true ] ; then prefix="Внимание: "; fi
    if [ -z $title ] ; then title='Напоминание'; fi
fi


##################################################################################

text_to_play="$prefix $text_to_play"

md5=$(echo -n "$text_to_play" | md5sum)
md5=${md5:0:32}
echo "md5: $md5"


voice_file="$cache_dir/$md5.mp3"
echo "voice_file: $voice_file"

if [ $use_cache == false -o ! -f $voice_file ] ; then
    #rm "$voice_file"

    if [ $use_google == true ] ; then
        echo "getting voice from google"
        wget -U "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.5) Gecko/20091102 Firefox/3.5.5" "http://translate.google.com/translate_tts?q=$text_to_play&tl=$enc" -O "$voice_file"
    fi
    if [ $use_google == false -o $? -ne 0 ] ; then 
        echo "generate voice with espeak"
        espeak -v$enc -s130 -w "$voice_file.wav" "$text_to_play"
        lame "$voice_file.wav" "$voice_file"
        rm "$voice_file.wav"
    fi
fi

beep

if [ -f $voice_file ] ; then
    l=$(mp3info -p "%S" cache/098f6bcd4621d373cade4e832627b4f6.mp3)
    let c=$timeout/$l+1
    mplayer -slave -loop $c $voice_file &
    PID=$!
    echo "pid: $PID"
fi

#res=$(${_zenity} --notification --title=${title} --text=${text} --timeout=${timeout})
${_zenity} --info --timeout=${timeout} --title="${title}" --text="${text}"
#notify-send $title $text

res=$?

if [ -n $PID ] ; then kill $PID; fi

if [ ${res} == "5" ] ; then 
    beep
    echo "sending mail..."
    echo "$text" | mail -s "$title" $mail
fi


exit 0


