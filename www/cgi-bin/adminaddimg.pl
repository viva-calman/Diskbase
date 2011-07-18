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
		    print $q->start_html(-style=>'../site.css',-title=>'Добавление образа');
		    open (AHEAD,"adminhead.inc");
		    while(<AHEAD>)
		    {
			print $_;
		    }
		    close AHEAD;
		    my $act=$q->param('act');
		    print "<b>Добавление нового образа</b></br></br>";
		    switch ($act)
		    {
			case 'add'
			{
			    #Добавление диска
			    my @entrys;
			    my $count=$q->param('count');
			    my $i=0;
			    print "<table class=\"maintable\" cellspacing=0 border=1 align=center>";
			    print "<tr><td><b>Название образа</b></td><td><b>Состояние</b></td></tr>";
			    while ($i<$count)
			    {
				my $paramname="entry".$i;  

				if (($entrys[$i]=$q->param($paramname)))
				{
				#Создание записи в базе
				    $sth=$dbh->prepare("insert into imgs (createdate) values ('$now')");
				    $sth->execute() or die $DBI::errstr;
				    $sth=$dbh->prepare("select max(id) from imgs");
				    $sth->execute() or die $DBI::errstr;
				    my $folderid=$sth->fetchrow_array();
				#Добавление образа ( передача данных скрипту обработки и создание данных в таблице
				
				    my $stat=`./unpack.sh unpack $entrys[$i] $folderid`;
				
				   # print "<table class=\"maintable\" cellspacing=0 border=1 align=center>";
				    print "<tr><td>";
				    $entrys[$i]=~s/\/.+\///;
				    print $entrys[$i];
				    print "</td><td>Добавлено (директория номер $folderid)</td><tr>";
				}
				
				$i++;
			    }
			    print "</table>";
			    print "<a href=\"".$sitename."/cgi-bin/admincp.pl\">вернуться в панель управления</a>";
			}
			case 'search'
			{
			    #Поиск образов в рабочей директории
			    my @list=`./unpack.sh search`;
			    if (@list)
			    {
				    print "<form action=\"adminaddimg.pl\" method=\"post\">";
				    print "<table class=\"maintable\" cellspacing=0 border=1 align=center>";
				    print "<tr><td></td><td><b>Имя найденого образа</b></td></tr>";
				    my $entry;
				    my $count=0;
				    my $chname;
				    foreach $entry (@list)
				    {
					$chname="entry".$count;    
					print "<tr><td><input type=\"checkbox\" name=\"$chname\" value=\"$entry\">";
					print "</td><td align=\"left\">";
					$entry=~s/\/.+\///;
					print $entry; 
					print "</td></tr>";
					$count++;
				    }
				    print "<input type=\"hidden\" name=\"count\" value=\"$count\">";
				    print "<input type=\"hidden\" name=\"act\" value=\"add\">";
				    print "<tr><td colspan=2><input type=\"submit\" value=\"Добавить\"></td></tr>";
				    print "</table></form>";
				    print "<br><a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a>";
			    }
			    else
			    {
				print "<b>Образы не найдены</b><br>";
				print "<a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a>"
			    }
			}
			else
			{
			    #
			}
		    }
		    print "</div></div>";
		    print $q->end_html();
		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('adminlogin.pl')
	}
