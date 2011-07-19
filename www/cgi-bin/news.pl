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
		print $q->redirect('login.pl');
		}
	else
		{
		#Код страницы
		    my $sth=$dbh->prepare("update usersession set sessiontime=$sesslong where id=$sessid");
		    $sth->execute();
		    print $q->header(-charset=>'utf-8');
		    print $q->start_html(-title=>'Новости',-style=>'../site.css');
		    open(CATEL,"catel.inc");
		    while(<CATEL>)
		    {
			print $_;
		    }
		    close (CATEL);
		    print "<table border=0 sellspacing=0 align=center width=100%><tr><td align=left><a href=\"".$sitename."/\">На главную</a>  ";
		    print "<a href=\"".$sitename."/cgi-bin/cat.pl\">Вернуться в каталог</a></td>";
		    print "<td align=right><a href=\"".$sitename."/cgi-bin/logout.pl\">Выход из системы</a></td></tr></table>";
		    print "</div><div class=\"text\">";


			    #Вывод списка новостей постранично	
			    my $page;
			    my @ids;
			    my $count=0;
			    #получение количества записей
				$sth=$dbh->prepare("select id from news order by id desc");
				$sth->execute() or die $DBI::errstr;
				while ((my $idl)=$sth->fetchrow_array())
				{
				    $ids[$count]=$idl;
				    $count++;
				}
			    #Если переменная $page не определена, приравниваем ее единице
			    if(!($page=$q->param('page')))
			    {
				$page=1;
			    }
			    
			    my $minlimit;
			    my $maxlimit;
			    my $minlim=$page*10;
			    my $maxlim=($page-1)*10;
			    if ($minlim>$count)
			    {
				$minlim=$count;
			    }
			    $minlimit=$ids[$minlim];
			    $maxlimit=$ids[$maxlim];
			    print "<b>список новостей</b>"; 
			    print "<table class=\"maintable\" border=1 cellspacing=0 align=center width=60%>";
			    $sth=$dbh->prepare("select * from news where id >'$minlimit' and id <='$maxlimit' order by id desc");
			    $sth->execute() or die $DBI::errstr;
			    my $lastid;
			    while (my ($id,$date,$header,$body)=$sth->fetchrow_array())
			    {
				print "<tr><td><table border=0 cellspacing=0 width=100%>";
				print "<tr><td align=left><span class=\"remarks\" ><b>Добавлено:</b> $date</span></td></tr><tr><td align=center><b>$header</b></td></tr>";
				print "<tr><td colspan=2 align=left>$body</td></tr></table>";
				print "</td><tr>";
				$lastid=$id;
			    }
			    print "</table><span class=\"remarks\">";
			    print "<table align=center border=0>";
			    #Создание ссылок перехода по страницам.
			    #Ссылка на предыдущую страницу
			    print "<tr><td>";
			    if($page>1)
			    {
				my $prewpage=$page-1;
				print "<a href=\"".$sitename."/cgi-bin/news.pl?page=$prewpage\">Предыдущая</a>"
			    }
			    print "</td><td><b>страница $page</b></td><td>";
			    if ($minlim<$count)
			    {
				my $nextpage=$page+1;
				print "<a href=\"".$sitename."/cgi-bin/news.pl?page=$nextpage\">Следующая</a>";
			    }
			    print "</td><td>";
			    print "</table></span>";
			    print "<br><a href=\"".$sitename."\">Вернуться на главную</a>";

		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('login.pl')
	}
