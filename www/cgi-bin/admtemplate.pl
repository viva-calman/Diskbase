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
		print $q->redirect('login.pl');
		}
	else
		{
		#Код страницы
		    my $sth=$dbh->prepare("update adminsession set sessiontime=$sesslong where id=$sessid");
		    $sth->execute();

		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('login.pl')
	}
