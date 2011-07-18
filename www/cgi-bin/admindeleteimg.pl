#!/usr/bin/perl -w

use strict;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use CGI;
use CGI::Cookie;
use Switch;
use POSIX qw(strftime);
#
#Определяем переменнные подключения к БД, имени хоста, и т.д.
my $sitename="http://localhost";
my $dsn="DBI:mysql:diskdb:localhost";
my $db_user="discbase";
my $db_password="windowssuxx";
my $now=strftime"%Y-%m-%d %H:%M:%S",localtime;
my $sesslong=time;
my $sessionlong=3600;
my $q=new CGI;
#
#Подключение к БД
my $dbh=DBI->connect($dsn,$db_user,$db_password);
#
#Запрос кукисов
my %cookies=fetch CGI::Cookie;
if ($cookies{'asessionkey'})
	{
	#
	#Проверка существования кукисов
	my $sesskey=$cookies{'asessionkey'}->value;
	my $sth=$dbh->prepare("select id,sessiontime from adminsession where sessionkey='$sesskey'");
	$sth->execute();
	my ($sessid,$sesstime)=$sth->fetchrow_array();
	if ($sessid eq '' or ($sesslong-$sesstime)>$sessionlong)
		{
		#	
		#Если кукисы просрочены - редирект
		$sth=$dbh->prepare("delete from adminsession where sessionkey='$sesskey'");
		$sth->execute();
		$sth->finish();
		print $q->redirect('adminlogin.pl');
		}
	else
		{
		#Код страницы
		    my $sth=$dbh->prepare("update adminsession set sessiontime=$sesslong where id=$sessid");
		    $sth->execute();
		    print $q->header(-charset=>'utf-8');
		    print $q->start_html(-title=>'Удаление образа',-style=>'../site.css');
		    open (ADMINHEAD,"adminhead.inc");
			while(<ADMINHEAD>)
			{
			    print $_;
			}
		    close (ADMINHEAD);
		    my $act=$q->param('act');
		    my $id=$q->param('id');
		    switch($act)
		    {
			case 'submit'
			{
			    $sth=$dbh->prepare("delete from imgs where id=$id");
			    $sth->execute() or die $DBI::errstr;
			    #вызов удаляющего скрипта
			    #
			    my $del=`./delete.sh $id`; 
			    #
			    print "<b>Образ удален</b><br><a href=\"".$sitename."/cgi-bin/admincat.pl\">Вернуться в каталог</a>";
			}
			else
			{
			    
	    		    print "<b>Вы хотите удалить образ?</b>";
			    print "<table class=\"maintable\" border=1, cellspacing=0 align=center>";
			    print "<tr><td><form action=\"admindeleteimg.pl\" method=\"post\">";
			    print "<input type=\"hidden\" value=\"submit\" name=\"act\"><input type=\"submit\" value=\"Удалить\"><input type=\"hidden\" value=\"$id\" name=\"id\">";
			    print "</form></td><td>";
			    print "<form action=\"admincat.pl\" method=\"post\"><input type=\"submit\" value=\"Отменить\"></form></td></tr></table>";
			}
		    }
		    print $q->end_html();
		    $sth->finish();
		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('adminlogin.pl')
	}
