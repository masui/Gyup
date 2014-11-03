# -*- coding: utf-8 -*-

require 'open-uri'
require 'nokogiri'
require 'httparty'
require 'net/http'
require 'uri'

#
# FirefoxをアクティブにしてURLを取得
#
system "osascript -e '
tell application \"Firefox\" to activate
delay 1
tell application \"System Events\" to tell process \"Firefox\"
  keystroke \"l\" using command down
  keystroke \"c\" using command down
end tell'"
sleep 1
page_url = `pbpaste`
sleep 1

#
# Gyazoを起動してGyazoのURLを取得
#
system "/Applications/Gyazo.app/Contents/MacOS/Gyazo"
sleep 1
gyazo_url = `pbpaste`

# Gyazoウィンドウを閉じる
# sleep 2
# system "osascript -e 'tell application \"Firefox\" to close window 1'"

#
# ページのタイトルを取得
#
page_title = Nokogiri::parse(HTTParty.get(page_url).body).xpath('//title').text

HTTParty.get URI.escape("http://gyazz.masuilab.org/__write?name=osusume&title=#{page_title}&data=[[#{page_url} #{gyazo_url}.png]]")

#url = URI.parse("http://gyazz.masuilab.org")
#res = Net::HTTP.start(url.host, url.port) {|http|
#  http.get(URI.escape("/__write?name=osusume&title=#{page_title}&data=[[#{page_url} #{gyazo_url}.png]]"))
#}

system "open 'http://gyazz.masuilab.org/osusume/#{page_title}'"
