#!/usr/bin/perl -w

use strict;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use CGI;
use CGI::Cookie;
use Switch;
use POSIX qw(strftime);
#
#Определяем переменные подключения к БД, имени хоста и т.д.
my $sitename="http://localhost";
my $dsn="DBI:mysql:diskdb:localhost";
my $db_user="discbase";
my $db_password="windowssuxx";
my $sessionlong=3600;
my $now=strftime"%Y-%m-%d %H:%M:%S",localtime;
my $sesslong=time;
#
#Подключение к БД
my $dbh=DBI->connect($dsn,$db_user,$db_password);
#
#Запрос кукисов
my %cookies=fetch CGI::Cookie;
#Проверка существования кукисов
if ($cookies{'sessionkey'})
	{
	#
	#проверка времени сессии
	my $sesskey=$cookies{'sessionkey'}->value;
	my $sth=$dbh->prepare("select id,sessiontime from usersession where sessionkey='$sesskey'");
	$sth->execute();
	my ($sessid,$sesstime)=$sth->fetchrow_array();
	if ($sessid eq '' or ($sesslong-$sesstime)>$sessionlong)
		{
		#
		#если сессия просрочена - редирект
		$sth=$dbh->prepare("delete from usersession where sessionkey='$sesskey'");
		$sth->execute();
		$sth->finish();
		my $q=new CGI;
		print $q->redirect('login.pl');
		}
	else
		{
		#Код страницы
		#Обновление времени сессии
		    my $sth=$dbh->prepare("update usersession set sessiontime=$sesslong where id=$sessid");
		    $sth->execute();
		    my $q=new CGI;
		    my $selid=$q->param('id');
		    print $q->header(-charset=>'utf-8');
		    print $q->start_html(-style=>"../site.css");
		    #
		    #Вывод заголовка, верхнего меню
		    open (HEAD, "catel.inc");
		    while(<HEAD>)
		    {
			    print $_;
		    }
		    print "<table border=0 sellspacing=0 align=center width=100%><tr><td align=left><a href=\"".$sitename."/\">На главную</a>  ";
		    print "<a href=\"".$sitename."/cgi-bin/cat.pl\">Вернуться в каталог</a></td>";
		    print "<td align=right><a href=\"".$sitename."/cgi-bin/logout.pl\">Выход из системы</a></td></tr></table>";
		    print "</div><div class=\"text\">";
		    my %typelist;
		    my %lablelist;
		    #
		    #Создаем хеши названий
		    my $sth=$dbh->prepare("select * from type");
		    $sth->execute();
		    while(my($typeid,$type)=$sth->fetchrow_array())
		    {
			   $typelist{$typeid}=$type;
		    }
		    $sth=$dbh->prepare("select * from lable");
		    $sth->execute();
		    while(my($lableid,$lable)=$sth->fetchrow_array())
		    {
			$lablelist{$lableid}=$lable;
		    }
		    #
		    #Выборка нужной записи
		    my $sth=$dbh->prepare("select * from imgs where id=$selid");
		    $sth->execute();
		    my ($id,$type,$title,$lable,$year,$number,$description,$createdate,$autorun)=$sth->fetchrow_array();
		    my $tabtitle;
		    #
		    #Определяем, что выводить - название издания или название диска
		    if($lable==5)
		    {
			$tabtitle=$title;
		    }
		    else
		    {
			$tabtitle=$lablelist{$lable};
		    }
		    #
		    #Вывод таблицы   
		    print "<table align=center border=1 cellspacing=0 width=700px class=\"maintable\">";
		    print "<tr><td><b>$tabtitle</b></td></tr>";
		    print "<tr><td>Номер $number за $year год<br><span class=\"remarks\"> (добавлено $createdate)</span></td></tr>";
    		    print "<tr><td>$typelist{$type}</td></tr>";
		    print "<tr><td align=left>$description</td></tr>";
		    print "<tr><td>";
		    print "<form action=\"mount.pl\" method=\"post\">";
		    print "<input type=\"hidden\" name=\"id\" value=\"".$id."\">";
		    print "<input type=\"hidden\" name=\"autorun\" value=\"".$autorun."\">";
		    print "<input type=\"submit\" value=\"Смонтировать образ\">";
		    print "</form></td></tr>";
		    print "<tr><td><span class=\"remarks\">Внимание, если у вас уже смонтирован какой-либо образ, он будет отмонтирован и заменен текущим</span></td></tr>";
		    
		    print "</table></div></div>";
		    print $q->end_html();
		    $sth->finish();
		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	my $q=new CGI;
	print $q->redirect('login.pl')
	}
