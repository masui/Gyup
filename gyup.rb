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

system "echo '' | pbcopy"
buffer = `pbpaste`
buffer.chomp!

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
  when /opera/i then "Opera"
  else "Firefox"
  end

#
# ブラウザをアクティブにしてCmd-L/Cmd-Cを送ってURLを取得
#
system "osascript -e '
tell application \"#{browser}\" to activate
tell application \"System Events\" to tell process \"#{browser}\"
  keystroke \"l\" using command down
  delay 0.2
  keystroke \"c\" using command down
end tell'"

starttime = Time.now.to_i
page_url = ''
while true do
  page_url = `pbpaste`
  page_url.chomp!
  break if page_url != buffer
  exit if Time.now.to_i - starttime > 5 # 5秒たったら終了
  puts page_url
  sleep 0.3
end

buffer = page_url
#
# GyazoにアップしてURLを取得
#
tmpfile = "/tmp/image_upload#{$$}.png"
system "screencapture -i \"#{tmpfile}\""
exit if !File.exist?(tmpfile)
gyazo = Gyazo::Client.new
gyazo_url = gyazo.upload(tmpfile)
File.delete(tmpfile)

#
# ページのタイトルを取得
# 文字コードのせいで(?)失敗することがある (#8)
#
html = HTTParty.get(page_url).body
html = NKF.nkf('-w',NKF.nkf('-j',html))
page_title = Nokogiri::parse(html).xpath('//title').text
page_title.gsub!(/"/,'\\"')
page_title.gsub!(/'/,"\\'")

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

puts page_title

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
