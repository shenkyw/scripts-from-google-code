#!/usr/bin/ruby
# Name:: nicoxml2ssa.rb
# Version:: Alpha1.release2
# Purpose:: Transforme NICO's subtitle xml into SSA format
# Usage:: nicoxml2ssa.rb -i input.xml -o output.ssa
#
# :FIXME: I used mplayer to load the output generated from this script.
#         It worked. But when I try to load the same file by other
#         program under windows, it didn't work. I don't know why.
#
# Author:: Shenk @ (PTT BBS in Taiwan)
# Blog:: http://blog.pixnet.net/Shenk
#

require 'optparse'
require 'rexml/document'
require 'iconv'

#字幕花多少時間去移動(ms)
Duration = 3000
#字幕移動數度變數(越大越快)
Speed = 0.5

#字體大小(pt?)
Fontsize = {"big"=>20, "normal"=>18, "small"=>12}
#畫面寬能塞多少半形字元
Fontwide = {"big"=>16*2, "normal"=>31*2, "small"=>38*2}
#字高(pt)
Fontheight =  {"big"=>384/7.6, "normal"=>384/11.25, "small"=>384/16.5}

#====以下這堆是關於SSA Styles的常數
Fontname="方正黑体"
PrimaryColour="&H00FFFFFF"; SecondaryColour="&H00FFFFFF"
OutlineColour="&H7F000000"; BackColour="&H00000000"
BorderStyle="1"; Outline="1"; Shadow="1"; MarginV="5"

PlayResX = 512
PlayResY = 384
#====以上這堆是關於SSA Styles的常數

#utf8轉utf16
iconv = Iconv.new("utf16", "utf8")

header = iconv.iconv <<HEADER
[Script Info]
Script Type: V4.00+
ScriptType: V4.00+
Collisions: Normal
PlayResX: #{PlayResX}
PlayResY: #{PlayResY}
Timer: 100.000
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontsize, Fontname, PrimaryColour, SecondaryColour, OutlineColour, BackColour, BorderStyle, Outline, Shadow, MarginV, Alignment
Style: normal,#{Fontsize["normal"]},#{Fontname},#{PrimaryColour},#{SecondaryColour},#{OutlineColour},#{BackColour},#{BorderStyle},#{Outline},#{Shadow},#{MarginV},9
Style: ue,#{Fontsize["normal"]},#{Fontname},#{PrimaryColour},#{SecondaryColour},#{OutlineColour},#{BackColour},#{BorderStyle},#{Outline},#{Shadow},#{MarginV},8
Style: shita,#{Fontsize["normal"]},#{Fontname},#{PrimaryColour},#{SecondaryColour},#{OutlineColour},#{BackColour},#{BorderStyle},#{Outline},#{Shadow},#{MarginV},2

[Events]
Format: Layer, Start, End, Style, Text
HEADER

OPTIONS = {
	:input => "/dev/stdin",
	:output => "/dev/stdout",
}

ARGV.options do |o|
	script_name = File.basename($0)

	o.banner = "Usage: #{script_name} [options]"
	o.separator ""
	o.separator "Options:"
	o.on("-i", "--input=xml_file", String,
	   "輸入的nico xml字幕檔")   { |OPTIONS[:input]| }
	o.on("-o", "--output=ssa_file", String,
	   "輸出的ssa字幕檔")      { |OPTIONS[:output]| }
	o.separator ""
	o.on_tail("-h", "--help", "Show this help message.") { puts o; exit }

	o.parse!
end

input = OPTIONS[:input]
output = OPTIONS[:output]

class Fixnum
	#change centisecond to time format
	def cs_to_s
		hour,min = self.divmod(60*60*100)
		min,sec = min.divmod(60*100)
		sec,under_sec  = sec.divmod(100)
		"%d:%02d:%02d.%02d" % [hour,min,sec,under_sec]
	end
end

class Comment
	attr_reader :vpos, :style #ue? shita?
	attr_accessor :vlocation
	def initialize(mail,vpos,text)
		@text,@vpos = text.gsub(/\n/,'\\N'),vpos.to_i

		@style = case mail
			when /ue/ : "ue"
			when /shita/ : "shita"
			else "normal"
		end

		@color = case mail
			when /red/ : "0000FF"
			when /blue/ : "FF0000"
			when /yellow/ : "00FFFF"
			when /orange/ : "4080FF"
			when /pink/ : "FF00FF"
			when /purple/ : "EF3B89"
			when /cyan/ : "FFFF00"
			when /green/ : "00FF00"
			else ""
		end
		
		@color = '{\\1c&H00'+@color+'}' unless @color.empty?

		@size = case mail
			when /big/ : "big"
			when /small/ : "small"
			else "normal"
		end
		
		@vlocation = Fontheight[@size]
	end

	#字幕出現座標回歸為最上端
	def reloc
		@vlocation = Fontheight[@size]
	end

	#此字幕影響到右邊邊框至此時間點
	def last_t
		text_wide = Speed*@text.length*512/Fontwide[@size]
		vpos + (Duration/10)*text_wide/(text_wide+PlayResX)
	end

	#建立此字幕的移動方法
	def move
		height = (@vlocation - Fontheight[@size]).to_i
		(@style == "normal")? 
		"{\\move(#{PlayResX+(Speed*@text.length*512/Fontwide[@size]).to_i},#{height},0,#{height},0,#{Duration})}":""
	end

	#轉成ssa語法
	def to_s
		fontsize = (@size == "normal")? "" : '{\\fs'+Fontsize[@size].to_s+'}'
		"Dialogue: 0,#{@vpos.cs_to_s},#{(@vpos+300).cs_to_s},#@style,#{fontsize}#@color#{self.move}#@text"
	end
end
 
#讀檔
#note:似乎應該排除掉太久以前的字幕

chats = Array.new
nicoxml = REXML::Document.new(File.open(input))
nicoxml.elements.each("packet/chat") do |chat|
	chats.push Comment.new(chat.attributes["mail"],chat.attributes["vpos"],chat.text)
end

#排序
chats = chats.sort{|x,y|x.vpos <=> y.vpos}

=begin
處理字幕出現於右邊垂直端的何處
作法：考慮所有一般字幕會影響右端的最後時間
	若不干擾此字幕的出現...就回歸原點

note:似乎會出現後出現跑比較快的會蓋掉前面出現跑比較慢的情形
=end
chats.each_index do |i|
	next unless chats[i].style == "normal"
	compair = Array.new
	i.downto(0) do |k|
		next if k == i
		break if chats[i].vpos - chats[k].vpos >= 300
		next unless chats[k].style == "normal"
		compair.push chats[k].vlocation if chats[k].last_t > chats[i].vpos
	end
	next if compair.empty?
	
	chats[i].vlocation += compair.max
	chats[i].reloc if chats[i].vlocation > PlayResY
end

ssa_file = File.new(output, "w")
ssa_file << header

chats.each{|x| ssa_file << iconv.iconv(x.to_s + "\n")}

