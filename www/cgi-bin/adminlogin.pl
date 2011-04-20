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
if ($cookies{'asessionkey'})
	{
	#
	#Если кукисы существуют...
	my $sesskey=$cookies{'asessionkey'}->value;
	my $sth=$dbh->prepare("select id,sessiontime from adminession where sessionkey='$sesskey'");
	$sth->execute();
	my ($sessid,$sesstime)=$sth->fetchrow_array();
	if ($sessid ne '' and ($sesslong-$sesstime)<3600)
		{
		#
		#...и не просрочены - редирект на главную
		$sth->finish();	
		#my $q=new CGI;
		$sitename=$sitename."cgi-bin/admincp.pl";
		print $q->redirect($sitename);
		}
	
	else
		{
		#
		#...просрочены - удаление из таблицы сессий
		$sth=$dbh->prepare("delete from adminsession where id=$sessid");
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
	my $sth=$dbh->prepare("select id,password from admins where username='$username'");
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
		open(FORM,"admformlogin.inc");
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
		my $c=new CGI::Cookie(-name=>'asessionkey',-value=>$sesskey);	
		$sth=$dbh->prepare("insert into adminsession (userid,sessionkey,sessionstart,sessiontime) values ($id,'$sesskey','$now',$sesslong)");
		$sth->execute();
		$sth->finish();
		print $q->header(-charset=>'utf-8',-cookie=>$c);
		print $q->start_html;
		print "Вход успешен<br><a href=\"".$sitename."cgi-bin/admincp.pl\">Нажмите для перехода на главную страницу</a>";
	}
	print "</div></div>";
	print $q->end_html;
}
else
{
	#
	#Отрисовка формы
	print $q->header(-charset=>'utf-8');
	print $q->start_html(-style=>'../site.css');
	open (HEAD,"head.inc");
	while(<HEAD>)
	{
		print $_;
	}
	close (HEAD);
	open(FORM,"admformlogin.inc");
	while(<FORM>)
	{
		print $_;
	}
	print "</div></div>";
	print $q->end_html;
}





