#!/usr/bin/ruby
#Purpose: Send each chat Session to you.
#	Please change the value of "mail" to your mail address first
#
#Usage: Transformed html(to STDOUT) | ./split.rb "mail title"
#Output: Each mail per Session in your mail box.
#-----------------------------------------
#目的：將轉換後的html寄到"mail",每一個Session一封
#	請先更改mail變數的值改成你的e-mail
#
#用法：輸出到STDOUT(輸入從STDIN) | ./split.rb "信件標題"
#輸出：每個Session一封信，在妳信箱
#
#Author：Shenk @ [PTT BBS in Taiwan]
#Blog：http://blog.pixnet.net/Shenk

require 'rexml/document'
require 'shell'

title=ARGV[0]

#Change to your e-mail address
mail="your@email.address"

content = ""
open("/dev/stdin") do |s| content = s.read end

xml = REXML::Document.new(content)
shell = Shell.new()

mail_exec="mutt -s "+title+" "+mail+' -e  "set content_type=text/html"'

xml.elements.each("/html/div/Session") do |s|
	shell.echo("\n"+s.to_s)|shell.system(mail_exec)
	sleep(10)
end
