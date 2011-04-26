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
		    print $q->start_html(-title=>'Список модераторов',-style=>'../site.css');
		    open (ADMINHEAD,"adminhead.inc");
		    while (<ADMINHEAD>)
		    {
			    print $_;
		    }
		    close (ADMIHEAD);
		    my $act=$q->param('act');
		    switch ($act)
		    {		    
		    case 'del'
		    {
			my $rmid=$q->param('id');
			my $error='Удаление невозможно';
			if ($rmid==1)
			{
			    print "<b>".$error."</b><br><a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a>"
			}   
			else
			{
			    my $sth=$dbh->prepare("delete from admins where id=$rmid");
			    $sth->execute() or die $DBI::errstr;
			    $sth->finish();
			    print "Пользователь удален<br><a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a>";
			}
    
		    }
		    case 'add'
		    {
			my $user=$q->param('name');
			my $pass=$q->param('pass');
			my $repass=$q->param('repass');
			my $errstate=0;
			my $error='';
			if ($pass ne $repass)
			{
			    $error='Пароли не совпадают';
			    $errstate=1;
			}
			if (length($pass)<8)
			{
			    $error='Длина пароля должна быть больше восьми символов';
			    $errstate=1;
			}
			if ($user=~ /\W/)
			{
			    $error='Имя пользователя содержит недопустимые символы';
			    $errstate=1;
			}
			my $sth=$dbh->prepare("select id from admins where username='$user'");
			$sth->execute() or die $DBI::errstr;
			if ((my $testid=$sth->fetchrow_array()) != "" )
			{
			    $error='Пользователь уже существует';
			    $errstate=1;
			}
			if ($errstate==1)
			{
			    print "<b>Ошибка: $error</b>";			    
			    print "<form action=\"adminmodlist.pl\" method=\"post\">";
			    print "<table cellspacing=0 border=1 class=\"maintable\" align=\"center\">";
			    print "<tr><td align=right>Имя пользователя:</td><td><input type=\"text\" name=\"name\" class=\"adminedit\" value=\"$user\"></td></tr>";
			    print "<tr><td align=right>Пароль:</td><td><input type=\"password\" name=\"pass\" class=\"adminedit\"></td></tr>";
			    print "<tr><td align=right>Повторите пароль:</td><td><input type=\"password\" name=\"repass\" class=\"adminedit\"></td></tr>";
			    print "<tr><td><input type=\"submit\" value=\"Создать\"></td><td><input type=\"reset\" value=\"Очистить\"></td></tr>";
			    print "<input type=\"hidden\" name=\"act\" value=\"add\">";
			    print "<tr><td colspan=2><br><a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a></td></tr>";
			    print "</table>";
			    print "</form>";
			    print $q->end_html();
			}
			else
			{   
			    my $crypt_pass=md5_hex($pass);	
			    my $sth=$dbh->prepare("insert into admins (username,password,createdate) values ('$user','$crypt_pass','$now')");
			    $sth->execute() or die $DBI::errstr;
			    $sth->finish();
			    print "<b>Пользователь добавлен</b><br>";
			    print "<a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a>";
			}

		    }
		    case 'addform'
		    {
			print "<b>Добавление модератора</b>";			    
			print "<form action=\"adminmodlist.pl\" method=\"post\">";
			print "<table cellspacing=0 border=1 class=\"maintable\" align=\"center\">";
			print "<tr><td align=right>Имя пользователя:</td><td><input type=\"text\" name=\"name\" class=\"adminedit\"></td></tr>";
			print "<tr><td align=right>Пароль:</td><td><input type=\"password\" name=\"pass\" class=\"adminedit\"></td></tr>";
			print "<tr><td align=right>Повторите пароль:</td><td><input type=\"password\" name=\"repass\" class=\"adminedit\"></td></tr>";
			print "<tr><td><input type=\"submit\" value=\"Создать\"></td><td><input type=\"reset\" value=\"Очистить\"></td></tr>";
			print "<input type=\"hidden\" name=\"act\" value=\"add\">";
			print "<tr><td colspan=2><br><a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a></td></tr>";
			print "</table>";
			print "</form>";
			print $q->end_html();
		    }
		    else
			{
			    print "<b>Управление списком модераторов</b>";
			    print "<table sellspacing=0 border=1 class=\"maintable\" align=center>";
			    print "<tr><td><b>Имя пользователя</b></td><td><b>Дата создания</b></td><td><b>действие</b></td></tr>";
			    my $sth=$dbh->prepare("select id,username,createdate from admins");
			    $sth->execute() or die $DBI::errstr;
			    while(my($id,$username,$createdate)=$sth->fetchrow_array())
				{
				    if($username eq 'admin')
				    {
					print "<tr bgcolor=#aaaaff ><td >$username</td><td>$createdate</td><td>Удаление невозможно</td></tr>";
				    }
				    else
				    {
					print "<tr><td>$username</td><td>$createdate</td>";    
					print "<td><a href=\"".$sitename."/cgi-bin/adminmodlist.pl?id=$id&act=del\">Удалить</a></td></tr>"
				    }
				}
			    print "<tr><td colspan=3><a href=\"".$sitename."/cgi-bin/adminmodlist.pl?act=addform\">Добавить нового модератора</a>";	
			    print "</table>";
			    print $q->end_html();
			    $sth->finish();
		        }
		    }
		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('adminlogin.pl')
	}
