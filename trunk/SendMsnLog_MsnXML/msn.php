#!/usr/bin/php
<?php
#Purpose: Trainsform msn chat log to readable html page.
#
#Usage: msn.phs chatlog.xml
#Output: output html page from STDOUT
#-----------------------------------------
#目的：將msn聊天紀錄xml轉為能直接閱讀的html網頁
#
#用法：msn.php chatlog.xml
#輸出：從STDOUT直接輸出html
#
#Author：Shenk @ [PTT BBS in Taiwan]
#Blog：http://blog.pixnet.net/Shenk

$MessageLog_xsl='<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<!-- Version 0.020080404 -->

	<xsl:template match="/">
		<html>
		<xsl:element name="Log" use-attribute-sets="Log"/>
			<div id="main">
			<xsl:apply-templates select="Log"/>
			</div>
		</html>
	</xsl:template>

	<xsl:template match="Log">
		<xsl:apply-templates/>
	  </xsl:template>

	<xsl:attribute-set name="Log">
		<xsl:attribute name="FirstSessionID">
			<xsl:value-of select="Log/@FirstSessionID"/>
		</xsl:attribute>
		<xsl:attribute name="LastSessionID">
			<xsl:value-of select="Log/@LastSessionID"/>
		</xsl:attribute>
	</xsl:attribute-set>

	<!-- template : Session -->
	<xsl:template name="SessionStart">
		<xsl:element name="Session" use-attribute-sets="Session"/>
	</xsl:template>

	<xsl:template name="SessionEnd">
		<xsl:element name="Session" use-attribute-sets="Session"/>
	</xsl:template>

	<xsl:attribute-set name="Session">
		<xsl:attribute name="SessionID">
			<xsl:value-of select="@SessionID"/>
		</xsl:attribute>
	</xsl:attribute-set>

	<!-- Message -->
	<xsl:template match="Message">
		<xsl:call-template name="SessionStart"/>
		<div id="Message">
			<div id="Imformation">
				(<xsl:element name="time" use-attribute-sets="time"><xsl:value-of select="@Time"/></xsl:element>)
				<from><xsl:value-of select="From/User/@FriendlyName"/></from> 對 
				<to><xsl:value-of select="To/User/@FriendlyName"/></to> 說:
			</div>
			<xsl:element name="div" use-attribute-sets="Text_style"><xsl:value-of select="string(Text)"/></xsl:element>
		</div>
		<xsl:call-template name="SessionEnd"/>
	</xsl:template>

	<xsl:attribute-set name="time">
		<xsl:attribute name="Date">
			<xsl:value-of select="@Date"/>
		</xsl:attribute>
		<xsl:attribute name="DateTime">
			<xsl:value-of select="@DateTime"/>
		</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="Text_style">
		<xsl:attribute name="id">Text</xsl:attribute>
		<xsl:attribute name="Style">
			<xsl:value-of select="Text/@Style"/>
		</xsl:attribute>
	</xsl:attribute-set>

	<!-- Leave -->
	<xsl:template match="Leave">
		<xsl:call-template name="SessionStart"/>
		<div id="leave">
				(<xsl:element name="time" use-attribute-sets="time"><xsl:value-of select="@Time"/></xsl:element>)
				<xsl:element name="time" use-attribute-sets="who"><xsl:value-of select="string(Text)"/></xsl:element>
		</div>
		<xsl:call-template name="SessionEnd"/>
	</xsl:template>

	<xsl:attribute-set name="who">
		<xsl:attribute name="FriendlyName">
			<xsl:value-of select="User/@FriendlyName"/>
		</xsl:attribute>
	</xsl:attribute-set>

	<!-- Invitation -->
	<xsl:template match="Invitation">
		<xsl:call-template name="SessionStart"/>
		<div id="Invitation">
				(<xsl:element name="time" use-attribute-sets="time"><xsl:value-of select="@Time"/></xsl:element>)
				<from><xsl:value-of select="From/User/@FriendlyName"/></from> 傳送
				<file><xsl:value-of select="string(File)"/></file> 
			<xsl:element name="div" use-attribute-sets="Text_style"><xsl:value-of select="string(Text)"/></xsl:element>
		</div>
		<xsl:call-template name="SessionEnd"/>
	</xsl:template>

	<!-- InvitationResponse -->
	<xsl:template match="InvitationResponse">
		<xsl:call-template name="SessionStart"/>
		<div id="InvitationResponse">
				(<xsl:element name="time" use-attribute-sets="time"><xsl:value-of select="@Time"/></xsl:element>)
				<from><xsl:value-of select="From/User/@FriendlyName"/></from> 傳送
				<file><xsl:value-of select="string(File)"/></file> 
			<xsl:element name="div" use-attribute-sets="Text_style"><xsl:value-of select="string(Text)"/></xsl:element>
		</div>
		<xsl:call-template name="SessionEnd"/>
	</xsl:template>
</xsl:stylesheet>';
?>

<?php
$doc = new DOMDocument();
$xsl = new XSLTProcessor();

$doc->loadXML($MessageLog_xsl);
$xsl->importStyleSheet($doc);

$doc->load($argv[1]);
$ori_html=split("\n",$xsl->transformToXML($doc));

	$pattern[0] = '%<Session SessionID="(.+)"></Session>(.*)<Session SessionID="\1"></Session>%';
	$pattern[1] = '%<Session SessionID=".+">(</Session>)(<Session SessionID=".+">)</Session>%';
	$pattern[2] = '%(<Session SessionID=".+">)</Session>(.+)%';
	$replacement[0] = '${2}';
	$replacement[1] = '${1}<hr/>${2}';
	$replacement[2] = '${1}${2}';
	
$ori_html[count($ori_html)-4]="</Session>";
	
foreach($ori_html  as $each_line){
	echo preg_replace($pattern, $replacement, $each_line)."\n";
}
?>
