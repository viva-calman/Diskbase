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
	#
	#Удаление сессии из базы
	my $sth=$dbh->prepare("delete from usersession where sessionkey='$sesskey'");
	$sth->execute() or die $DBI::errstr;
	my $q=new CGI;
	print $q->header(-charset=>'utf-8');
	print $q->start_html(-title=>'Выход из системы');
	print "Вы успешно вышли из системы.<br><a href=\"".$sitename."\">Перейти на главную страницу</a>";

	$sth->finish();
	$q->end_html();
	}	
else
	{
	#
	#Если кукисов нет - редирект
	my $q=new CGI;
	print $q->redirect($sitename);
	}
