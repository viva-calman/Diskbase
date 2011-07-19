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
print $q->header(-charset=>'utf-8');
print $q->start_html(-title=>'Главная страница',-style=>'../site.css');

#
#Подключение к БД
my $dbh=DBI->connect($dsn,$db_user,$db_password);
sub pagegen {
    my $sth=$dbh->prepare("select * from news order by id desc limit 5");
    $sth->execute() or die $DBI::errstr;
    print "<b>Последние новости</b>";
    print "<table border=0 cellspacing=0 align=center width=60% class=\"maintable\">";
    while (my( $id,$date,$header,$body)=$sth->fetchrow_array())
    {
	print "<tr><td><table border=0 cellspacing=0 align=center>";
	print "<tr><td align=left><span class=\"remarks\">$date</span></td></tr><tr><td align=center><b>$header</b></td></tr>";
	print "<tr><td >$body</td></tr></table></td></tr><tr><td><hr></td></tr>";
    }
    print "</table>";
    $sth->finish();
}
sub menugen {
    open (CATEL,"catel.inc");
    while(<CATEL>)
    {
	print $_;
    }
    close (CATEL);
    print "<table border=0 sellspacing=0 align=center width=100%><tr>";
    print "<td align=right><a href=\"".$sitename."/cgi-bin/login.pl\">Вход</a><a href=\"".$sitename."/help.html\">Помощь</a>  </td></tr></table>";
    print "</div><div class=\"text\">";
  
}


#
#Запрос кукисов
my %cookies=fetch CGI::Cookie;
if ($cookies{'sessionkey'})
	{
	#
	#Проверка существования кукисов
	my $sesskey=$cookies{'sessionkey'}->value;
	my $sth=$dbh->prepare("select id,sessiontime from usersession where sessionkey='$sesskey'");
	$sth->execute();
	my ($sessid,$sesstime)=$sth->fetchrow_array();
	if ($sessid eq '' or ($sesslong-$sesstime)>$sessionlong)
		{
		#	
		#Если кукисы просрочены - редирект
		$sth=$dbh->prepare("delete from usersession where sessionkey='$sesskey'");
		$sth->execute();
		$sth->finish();
		&menugen();
		&pagegen();
		}
	else
		{
		#Код страницы
		    my $sth=$dbh->prepare("update usersession set sessiontime=$sesslong where id=$sessid");
		    $sth->execute();
		    #
		    #Вывод заголовка, верхнего меню
		    open (HEAD, "catel.inc");
		    while(<HEAD>)
		    {
			    print $_;
		    }
		    close (HEAD);
		    print "<table border=0 sellspacing=0 align=center width=100%><tr><td align=left><a href=\"".$sitename."/\">На главную</a>  ";
		    print "<a href=\"".$sitename."/cgi-bin/cat.pl\">В каталог</a></td>";
		    print "<td align=right><a href=\"".$sitename."/help.html\">Помощь</a>  <a href=\"".$sitename."/cgi-bin/logout.pl\">Выход из системы</a></td></tr></table>";
		    print "</div><div class=\"text\">";

		    &pagegen();
		     print "<a href=\"".$sitename."/cgi-bin/news.pl\">Все новости</a>";
		    print "</div></div>";
		    print $q->end_html();
		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	&menugen();
	&pagegen();
	}
