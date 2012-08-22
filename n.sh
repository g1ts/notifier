#!/bin/bash

# need: zenity, beep, enca, md5sum, wget, mplayer

cd -P "$( dirname "${BASH_SOURCE[0]}" )"

_zenity="/usr/bin/zenity"
timeout=10

source ./mail

title=$1
if [ -z $title ] ; then title='Напоминание'; fi
text=$2
if [ -z $text ] ; then text=`date`; fi
text_to_play=$3

md5=$(echo -n "$text_to_play" | md5sum)
md5=${md5:0:32}
echo "md5: $md5"
enc=$(echo "$text_to_play" | enca)
echo "enc: $enc"

if [ "$enc" == "7bit ASCII characters" ] ; then
    enc="en"
else
    enc="ru"
fi

voice_file="./cache/$md5.mp3"
echo "voice_file: $voice_file"

if ! [ -f $voice_file ] ; then
    echo "getting voice..."
    # espeak  -vru -s130 "text"
    wget -U "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.5) Gecko/20091102 Firefox/3.5.5" "http://translate.google.com/translate_tts?q=$text_to_play&tl=$enc" -O $voice_file
fi

beep

if [ -f $voice_file ] ; then
    mplayer -slave -loop 10 $voice_file &
    PID=$!
    echo "pid: $PID"
fi

#res=$(${_zenity} --notification --title=${title} --text=${text} --timeout=${timeout})
$(${_zenity} --info --timeout=${timeout} --title="${title}" --text="${text}" )
#notify-send $title $text

res=$?

if [ -n $PID ] ; then kill $PID; fi

if [ ${res} == "5" ] ; then 
    beep
    echo "sending mail..."
    echo "$text" | mail -s "$title" $mail
fi


exit 0


