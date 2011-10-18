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
#Определение переменных для подключения к БД, имени хоста и т.д.
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
	#Если кукисы есть и...
	my $sesskey=$cookies{'sessionkey'}->value;
	my $sth=$dbh->prepare("select id,sessiontime from usersession where sessionkey='$sesskey'");
	$sth->execute();
	my ($sessid,$sesstime)=$sth->fetchrow_array();
	if ($sessid ne '' and ($sesslong-$sesstime)<$sessionlong)
		{
		#
		#...не пророчены - редирект
		$sth->finish();	
		#my $q=new CGI;
		print $q->redirect($sitename);
	
		}
	
	else
		{
		#
		#просрочены - удаление из таблицы сессий и вывод формы регистрации
		$sth=$dbh->prepare("delete from usersession where id=$sessid");
		$sth->execute();
		}
	}
#
#Отрисовка формы	
#my $q= new CGI;
print $q->header(-charset=>'utf-8');
my $act=$q->param('act');
print $q->start_html(-style=>'../site.css',-title=>'Регистрация');
open (HEAD,"head.inc");
while(<HEAD>)
{
	print $_;
}
close (HEAD);
#
#Действие - создать
if ($act eq 'create')
{
	my $username=$q->param('username');
	my $pass=$q->param('password');
	my $password=md5_hex($pass);
	my $repassword=md5_hex($q->param('repassword'));
	my $errstate=0;
	my $errmessage;
	#
	#Тут будет проверка введенных символов и существования записей
	#
	my $sth=$dbh->prepare("select id from users where username='$username'");
	$sth->execute();
	if((my $check=$sth->fetchrow_array()))
	{
	    $errstate=1;
	    $errmessage="Ошибка:<br>Пользователь с таким именем уже существует";
	}
	else
	{
	    if($password ne $repassword)
	    {
		$errstate=1;
		$errmessage="Ошибка<br>Введенные пароли не совпадают";
	    }   
	    else
	    {
		if($username=~ /\W/)
		{
		    $errstate=1;
		    $errmessage="Ошибка:<br>Имя пользователя содержит недопустимые символы";
		}
		else
		{
		    if(length($pass)<6)
		    {
			$errstate=1;
			$errmessage="Ошибка:<br>Слишком короткий пароль";
		    }
		}
	    }
	}
	if($errstate==1)
	{
	print "<h4>".$errmessage."</h4>";	
	open(FORM,"formreg.inc");
	while(<FORM>)
		{
		print $_;
		}
		close (FORM);
	}
	else
	{	
		#
		#Создание пользователя
		$sth=$dbh->prepare("insert into users (username,password,createdate,status) values ('$username','$password','$now',0)");
		$sth->execute();
		my $user=`sudo ./reg.sh $username $pass`;
		print "Регистрация успешна, вы можете войти на сайт под вашим именем<br><a href=\"".$sitename."\">Нажмите для перехода на главную страницу</a>";
	}
	print "</div></div>";
	print $q->end_html;
	$sth->finish();
}
else
{
	#
	#Вывод формы регистрации
	open(FORM,"formreg.inc");
	while(<FORM>)
	{
		print $_;
	}
	close(FROM);
	print "<a href=\"".$sitename."\">На главную</a>";
	print "</div></div>";
	print $q->end_html;
}





