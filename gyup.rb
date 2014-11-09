# -*- coding: utf-8 -*-
#
# Gyup: WebページをGyazoってGyazzページとして登録する
#
# * Platypusを使うとエンコーディングがASCIIだと思われてしまうので
#   ひたすらforce_encodingしている。
# * HTMLからタイトル取得に失敗することもあるのでNKFを使って
#   ごまかしている。
# * ~/.gyup に設定を書く
# {
#   gyazz_name: "osusume",
#   text_template:'[[#{page_url} #{gyazo_url}.png]]
# [[増井.icon]]',
# }
#
#

require 'nokogiri'
require 'httparty'
require 'uri'
require 'nkf'
require 'json'
require 'gyazo'

config = {
  gyazz_url: "http://gyazz.masuilab.org", # gyazz.com であるべき
  gyazz_name: "osusume",
  text_template: '[[#{page_url} #{gyazo_url}.png]]',
}

configfile = File.expand_path("~/.gyup")
if File.exist?(configfile)
  conftext = NKF.nkf('-w',NKF.nkf('-j',File.read(configfile)))
  conf = eval(conftext.force_encoding("utf-8"))
  conf.each { |key,val|
    config[key] = val
  }
end

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
page_title.gsub!(/\'/,"\\\\'")

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
if page_title == '' # キャンセル操作したら終了
  STDERR.puts "Operation canceled"
  exit
end

#
# ページがすでに存在するかチェック
#
contents = ''
begin
  auth = {:username => "pitecan", :password => "masu1lab"}
  json = HTTParty.get(URI.escape("#{config[:gyazz_url]}/#{config[:gyazz_name]}/#{page_title}/json".force_encoding("utf-8")), :basic_auth => auth).body
  data = JSON.parse(json)
  contents = data['data'][0].to_s
rescue
end

#cmd = "#{config[:gyazz_url]}/#{config[:gyazz_name]}/#{page_title}/json".force_encoding("utf-8")
#puts "cmd = #{cmd}"
#puts "escape = #{URI.escape(cmd)}"
#puts "contents = #{contents}"

#
# 既存ページがなければ新規作成
#

config.each { |key,val|
  s = config[key].force_encoding("utf-8")
  config[key] = s
}

template = config[:text_template]
template = NKF.nkf('-w',NKF.nkf('-j',template))
data = eval('"'+template+'"').force_encoding("utf-8")

if contents == '' || contents == "(empty)" then # 新規ページ
  #
  # Gyazzページ作成
  #
  #s = "".force_encoding("utf-8")
  #s = "#{config[:gyazz_url]}/__write?name=#{config[:gyazz_name]}&title=#{page_title}&data=#{data}"
  s = config[:gyazz_url]
  s += "/__write?name="
  s += config[:gyazz_name]
  s += "&title="
  s += page_title
  s += "&data="
  s.force_encoding("utf-8")
  s += data
  s = NKF.nkf('-w',NKF.nkf('-j',s))
  HTTParty.get URI.escape(s)
end

#
# Gyazzページをブラウザで開く
#
system "open '#{config[:gyazz_url]}/osusume/#{page_title}'"
