# -*- coding: utf-8 -*-
#
# WebページをGyazoってGyazzの推薦ページに登録する
#

require 'open-uri'
require 'nokogiri'
require 'httparty'
require 'net/http'
require 'uri'

GYAZZNAME = "osusume"

#
# デフォルトブラウザを知る
#
line = `defaults read com.apple.LaunchServices | grep -C3 'LSHandlerURLScheme = http;' | grep LSHandlerRoleAll | uniq`
line =~ /"(.*)"/
id = $1
browser = 
  case id
  when /safari/i then "Safari"
  when /chrome/i then "Chrome"
  else "Firefox"
  end

#
# ブラウザをアクティブにしてURLを取得
#
system "osascript -e '
tell application \"#{browser}\" to activate
delay 1
tell application \"System Events\" to tell process \"#{browser}\"
  keystroke \"l\" using command down
  keystroke \"c\" using command down
end tell'"

sleep 1
page_url = `pbpaste`

#
# Gyazoを起動してGyazoのURLを取得
#
system "/Applications/Gyazo.app/Contents/MacOS/Gyazo"
sleep 1
gyazo_url = `pbpaste`
sleep 1

# Gyazoウィンドウを閉じる (#7)
# sleep 2
# system "osascript -e 'tell application \"#{browser}\" to close window 1'"

#
# ページのタイトルを取得
# 失敗することがある (#8)
#
page_title = Nokogiri::parse(HTTParty.get(page_url).body.force_encoding("utf-8")).xpath('//title').text

#
# ページタイトル編集ダイアログを出す (#4)
#
page_title = `osascript -e '
tell application \"Finder\" to activate
tell application \"Finder\"
  display dialog (\"Gyazzページタイトル\") default answer (\"#{page_title}\")
  set myResult to text returned of result
end tell'`
page_title.chomp!

#
# Gyazzページ作成
#
HTTParty.get URI.escape("http://gyazz.masuilab.org/__write?name=#{GYAZZNAME}&title=#{page_title}&data=[[#{page_url} #{gyazo_url}.png]]")

#
# Gyazzページをブラウザで開く
#
system "open 'http://gyazz.masuilab.org/osusume/#{page_title}'"
