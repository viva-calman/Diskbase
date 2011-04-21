#!/usr/bin/perl -w

use strict;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use CGI;
use CGI::Cookie;
use Switch;
use POSIX qw(strftime);
use Digest::MD5 qw(md5_hex);
#
#
my $sitename="http://localhost/";
my $dsn="DBI:mysql:diskdb:localhost";
my $db_user="discbase";
my $db_password="windowssuxx";
my $now=strftime"%Y-%m-%d %H:%M:%S",localtime;
my $sesslong=time;
my $q=new CGI;
#
#
my $dbh=DBI->connect($dsn,$db_user,$db_password);
#
#
my %cookies=fetch CGI::Cookie;
if ($cookies{'sessionkey'})
	{
	#
	#Если кукисы существуют...
	my $sesskey=$cookies{'sessionkey'}->value;
	my $sth=$dbh->prepare("select id,sessiontime from usersession where sessionkey='$sesskey'");
	$sth->execute();
	my ($sessid,$sesstime)=$sth->fetchrow_array();
	if ($sessid ne '' and ($sesslong-$sesstime)<3600)
		{
		#
		#...и не просрочены - редирект на главную
		$sth->finish();	
		print $q->redirect($sitename);
		}
	
	else
		{
		#
		#...просрочены - удаление из таблицы сессий
		$sth=$dbh->prepare("delete from usersession where id=$sessid");
		$sth->execute();
		}
	}
#my $q= new CGI;
my $act=$q->param('act');
#
#Действие авторизации
if ($act eq 'login')
{
	my $username=$q->param('username');
	my $password=md5_hex($q->param('password'));
	my $errstate;
	my $errmessage;
	my $sth=$dbh->prepare("select id,password from users where username='$username' and status=0");
	$sth->execute();
	my ($id, $checkpass)=$sth->fetchrow_array();
	$sth->finish();
#Тут бубет проверка введенных символов
	if ($checkpass eq $password)
	{
		$errstate=0;
	}
	else
	{
		#
		#Ошибка логина
		$errstate=1;
		$errmessage="Неверные данные пользователя<br>если вы забыли свой пароль, обратитесь к администратору";
	}
	if($errstate==1)
	{
		print $q->header(-charset=>'utf-8');
		print $q->start_html(-style=>'../site.css');
		open (HEAD,"head.inc");
		while(<HEAD>)
		{
			print $_;
		}	
		close (HEAD);
	
		print "<h4>".$errmessage."</h4>";	
		open(FORM,"formlogin.inc");
		while(<FORM>)
			{
			print $_;
			}
			close (FORM);
	}
	else
	{
		#
		#Создание новой сессии
		my $sesskey=md5_hex($now);
		my $c=new CGI::Cookie(-name=>'sessionkey',-value=>$sesskey);	
		$sth=$dbh->prepare("select lastdisk from users where username='$username'");
		$sth->execute();
		my $lastdisk=$sth->fetchrow_array();
		$sth=$dbh->prepare("insert into usersession (userid,sessionkey,sessionstart,sessiontime,diskid) values ($id,'$sesskey','$now',$sesslong,$lastdisk)");
		$sth->execute();
		$sth->finish();
		print $q->header(-charset=>'utf-8',-cookie=>$c);
		print $q->start_html(-title=>'Вход успешен');
		print "Вход успешен<br><a href=\"".$sitename."\">Нажмите для перехода на главную страницу</a>";
	}
	print "</div></div>";
	print $q->end_html;
}
else
{
	#
	#Отрисовка формы
	print $q->header(-charset=>'utf-8');
	print $q->start_html(-style=>'../site.css',-title=>'Страница входа');
	open (HEAD,"head.inc");
	while(<HEAD>)
	{
		print $_;
	}
	close (HEAD);
	open(FORM,"formlogin.inc");
	while(<FORM>)
	{
		print $_;
	}
	close(FORM);
	print "</div></div>";
	print $q->end_html;
}





