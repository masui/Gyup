# -*- coding: utf-8 -*-
#
# WebページをGyazoってGyazzの推薦ページに登録する
#

require 'nokogiri'
require 'httparty'
require 'uri'
require 'nkf'
require 'gyazo'

GYAZZ_URL     = "http://gyazz.masuilab.org" # gyazz.com であるべき
GYAZZ_NAME    = "osusume"
# GYAZO_COMMAND = "/Applications/Gyazo.app/Contents/MacOS/Gyazo"

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
# ブラウザをアクティブにしてCmd-L/Cmd-Cを送ってURLを取得
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
## system GYAZO_COMMAND
## sleep 1
## gyazo_url = `pbpaste`
## sleep 1

tmpfile = "/tmp/image_upload#{$$}.png"
system "screencapture -i \"#{tmpfile}\""
if File.exist?(tmpfile) then
  system "sips -d profile --deleteColorManagementProperties \"#{tmpfile}\""
  dpiWidth = `sips -g dpiWidth "#{tmpfile}" | awk '/:/ {print $2}'`
  dpiHeight = `sips -g dpiHeight "#{tmpfile}" | awk '/:/ {print $2}'`
  pixelWidth = `sips -g pixelWidth "#{tmpfile}" | awk '/:/ {print $2}'`
  pixelHeight = `sips -g pixelHeight "#{tmpfile}" | awk '/:/ {print $2}'`
  if (dpiWidth.to_f > 72.0 and dpiHeight.to_f > 72.0) then
    width = pixelWidth.to_f * 72.0 / dpiWidth.to_f
    height = pixelHeight.to_f* 72.0 / dpiHeight.to_f
    system "sips -s dpiWidth 72 -s dpiHeight 72 -z #{height} #{width} \"#{tmpfile}\""
  end
end
if !File.exist?(tmpfile) then
  exit
end
g = Gyazo::Client.new
gyazo_url = g.upload(tmpfile)
File.delete(tmpfile)

sleep 1

# Gyazoウィンドウを閉じる (#7)
# sleep 2
# system "osascript -e 'tell application \"#{browser}\" to close window 1'"

#
# ページのタイトルを取得
# 文字コードのせいで(?)失敗することがある (#8)
#
html = HTTParty.get(page_url).body
html = NKF.nkf('-w',NKF.nkf('-j',html))
page_title = Nokogiri::parse(html).xpath('//title').text
page_title.gsub!(/"/,'\\"')

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
#HTTParty.get URI.escape("#{GYAZZ_URL}/__write?name=#{GYAZZ_NAME}&title=#{page_title}&data=[[#{page_url} #{gyazo_url}.png]]")
s = "#{GYAZZ_URL}/__write?name=#{GYAZZ_NAME}&title=#{page_title}&data=[[#{page_url} #{gyazo_url}.png]]"
s = NKF.nkf('-w',NKF.nkf('-j',s))
HTTParty.get URI.escape(s)

#
# Gyazzページをブラウザで開く
#
system "open '#{GYAZZ_URL}/osusume/#{page_title}'"
