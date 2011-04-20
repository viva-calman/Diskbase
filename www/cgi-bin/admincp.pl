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
		    print $q->start_html(-style=>'../site.css');
		    open (ADMINHEAD,"adminhead.inc");
		    while (<ADMINHEAD>)
		    {
			print $_;
		    }
		    print "<table class=\"maintable\" cellspacing=0 border=1 align=\"center\">";       
		    print "<tr><td>Каталог</td><td>Активные пользователи</td><td>Действия</td></tr>";
		    print "<tr><td>";
		    #Функция вывода сокращенного каталога


		    print "</td><td>";
		    #Функция вывода активных пользователей


		    print "</td><td>";
		    #Таблица действий
			print "<table cellspacing=0 border=0 align=\"center\">";
			print "<tr><td ><b>Управление пользователями</b></td></tr>";
			print "<tr><td align=left>Список пользователей</td></tr>";
			print "<tr><td align=left>Активные сессии пользователей</td></tr>";
			print "<tr><td><b>Управление каталогом</b></td></tr>";
			print "<tr><td align=left>Просмотр каталога</td></tr>";
			print "<tr><td align=left>Добавление нового диска</td></tr>";
			print "<tr><td><b>Администрирование</b></td></tr>";
			print "<tr><td align=left>Список администраторов</td></tr>";
			print "<tr><td align=left>Смена пароля администратора</td></tr>";
			print "</table>";
		    print "</td></tr>";
		    print "</table>";
		    print "</div>";
		    print $q->end_html();
		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('adminlogin.pl')
	}
