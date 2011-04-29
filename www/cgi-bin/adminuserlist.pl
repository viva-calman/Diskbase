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
		    print $q->start_html(-title=>'Список пользователей',-style=>'../site.css');
		    #Выводим заголовок и шапку
		    open (ADMINHEAD,"adminhead.inc");
		    while (<ADMINHEAD>)
		    {
			    print $_;
		    }
		    close (ADMINHEAD);
		    my $act=$q->param('act');
		    switch ($act)
		    {
			    case 'delete'
			    {
			    #Удаление пользователя
				my $id=$q->param('id');
				$sth=$dbh->prepare("select username from users where id=$id");
				$sth->execute() or die $DBI::errstr;
				my $username=$sth->fetchrow_array();
				print "<b>Вы действительно хотите удалить пользователя ".$username."?";
				print "<br><a href=\"".$sitename."/cgi-bin/adminuserlist.pl?act=submitdelete&id=$id\">Да, я хочу удалить пользователя</a><br><br><a href=\"".$sitename."/cgi-bin/adminuserlist.pl\">Нет, я хочу вернуться в список пользователей</a>";
			    }
			    case 'submitdelete'
			    {
			    #Подтвержение удаления пользователя
				my $id=$q->param('id');
				$sth=$dbh->prepare("delete from users where id=$id");
				$sth->execute() or die $DBI::errstr;
				$sth=$dbh->prepare("delete from usersession where userid=$id");
				$sth->execute() or die $DBI::errstr;
				$sth->finish();
				print "Пользователь удален. <br><a href=\"".$sitename."/cgi-bin/adminuserlist.pl\">Вернуться в список пользователей</a>";
			    }
			    case 'change'
			    {
			    #Смена данных пользователя	   
				my $uid=$q->param('id');
				$sth=$dbh->prepare("select id,username,createdate,status,lastvisit from users where id=$uid");
				$sth->execute() or die $DBI::errstr;
				my ($id,$username,$createdate,$status,$lastvisit)=$sth->fetchrow_array();
				print "<b>Изменение данных пользователя</b>";
				print "<form action=\"adminuserlist.pl\" method=\"post\">";
				print "<table cellspacing=0 border=1 class=\"maintable\" align=\"center\">";
				print "<tr><td align=right>Имя пользователя:</td><td>$username</td></tr>";
				print "<tr><td align=right>Дата регистрации:</td><td>$createdate</td></tr>";
    				print "<tr><td align=right>Дата последнего посещения:</td><td>$lastvisit</td></tr>";
    				print "<tr><td align=right>Статус</td><td align=left>";
				print "<select name=\"status\" class=\"adminedit\">";
				if ($status==0)
				{
				    print "<option value=0 selected>Активен</option>";
				    print "<option value=1>Заблокирован</option>";
				}
				else
				{
				    print "<option value=0>Активен</option>";
				    print "<option value=1 selected>Заблокирован</option>";
				}
				print "</select>";
				print "</td></tr>";
    				print "<tr><td align=right>Задать пароль:<br><span class=\"remarks\">Заполнять только для изменения пароля</span></td><td><input type=\"password\" name=\"pass\" class=\"adminedit\"></td></tr>";
    				print "<tr><td align=right>Повторить пароль:</td><td><input type=\"password\" name=\"repass\" class=\"adminedit\"></td></tr>";
				print "<tr><td colspan=2><input type=\"submit\" value=\"Изменить\"></td></tr>";
				print "<tr><td colspan=2><a href=\"".$sitename."/cgi-bin/adminuserlist.pl\">Вернуться в список</a></td></tr>";
				print "<input type=\"hidden\" name=\"act\" value=\"submitchange\">";
				print "<input type=\"hidden\" name=\"id\" value=$id>";
				print "</table></form>";
			    }
			    case 'submitchange'
			    {
				my $pass=$q->param('pass');
				my $repass=$q->param('repass');
				my $status=$q->param('status');
				my $id=$q->param('id');
				my $errstate=0;
				my $errmesg;
				if ($pass ne '')
				{
				    if ($pass ne $repass)
				    {
					$errstate=1;
					$errmesg="Пароли не совпадают";
				    }
				    if (length($pass)<6)
				    {
					$errstate=1;
					$errmesg="Пароль должен быть длиннее шести символов";
				    }
				}
				my $encpass=md5_hex($pass);
				if ($errstate==1)
				{
				    $sth=$dbh->prepare("select id,username,createdate,status,lastvisit from users where id=$id");
				    $sth->execute() or die $DBI::errstr;
				    my ($id,$username,$createdate,$status,$lastvisit)=$sth->fetchrow_array();
				    print "<b>Изменение данных пользователя</b><br>";
				    print "<b>$errmesg</b>";
				    print "<form action=\"adminuserlist.pl\" method=\"post\">";
				    print "<table cellspacing=0 border=1 class=\"maintable\" align=\"center\">";
				    print "<tr><td align=right>Имя пользователя:</td><td>$username</td></tr>";
				    print "<tr><td align=right>Дата регистрации:</td><td>$createdate</td></tr>";
				    print "<tr><td align=right>Дата последнего посещения:</td><td>$lastvisit</td></tr>";
				    print "<tr><td align=right>Статус</td><td align=left>";
				    print "<select name=\"status\" class=\"adminedit\">";
				    if ($status==0)
				    {
					print "<option value=0 selected>Активен</option>";
					print "<option value=1>Заблокирован</option>";
				    }
				    else
				    {
					print "<option value=0>Активен</option>";
					print "<option value=1 selected>Заблокирован</option>";
				    }
				    print "</select>";
				    print "</td></tr>";
				    print "<tr><td align=right>Задать пароль:<span class=\"remarks\">Заполнять только для изменения пароля</span></td><td><input type=\"password\" name=\"pass\" class=\"adminedit\"></td></tr>";
				    print "<tr><td align=right>Повторить пароль:</td><td><input type=\"password\" name=\"repass\" class=\"adminedit\"></td></tr>";
				    print "<tr><td colspan=2><input type=\"submit\" value=\"Изменить\"></td></tr>";
				    print "<tr><td colspan=2><a href=\"".$sitename."/cgi-bin/adminuserlist.pl\">Вернуться в список</a></td></tr>";
				    print "<input type=\"hidden\" name=\"act\" value=\"submitchange\">";
				    print "<input type=\"hidden\" name=\"id\" value=$id>";
				    print "</table></form>";
				}
				else
				{   
				    my $quer;	
				    if($pass eq '')
				    {
					$quer="update users set status=$status where id=$id";
				    }
				    else
				    { 
					$quer="update users set status=$status,password='$encpass' where id=$id";
				    }
				    $sth=$dbh->prepare("$quer");
				    $sth->execute() or die $DBI::errstr;
				    if($status==1)
				    {
					$sth=$dbh->prepare("delete from usersession where userid=$id");
					$sth->execute() or die $DBI::errstr;
				    }
				    $sth->finish();
				    print "Изменение успешно.<br><a href=\"".$sitename."/cgi-bin/adminuserlist.pl\">Вернуться в список пользователей</a>"; 
				}

			    }
			    else
			    {
			    #Вывод таблицы пользователей	    
				$sth=$dbh->prepare("select id,username,createdate,status,lastvisit from users");	
				$sth->execute() or die $DBI::errstr;
				print "<b>Управление списком пользователей</b>";
				print "<table cellspacing=0 border=1 class=\"maintable\" align=\"center\">";
				print "<tr><td><b>Имя пользователя</b></td><td><b>Дата регистрации</b></td><td><b>Последнее посещение</b></td><td><b>Статус</b></td><td><b>Действие</b></td></tr>";
				while (my ($id,$username,$createdate,$status,$lastvisit)=$sth->fetchrow_array())
				{
				    print "<tr><td>$username</td><td>$createdate</td><td>$lastvisit</td><td>";
				    if ($status == 0)
				    {
					    print "Активен";
				    }
				    else
				    {
					    print "Заблокирован";
				    }
				    print "</td><td><a href=\"".$sitename."/cgi-bin/adminuserlist.pl?act=change&id=$id\">Изменить</a>/<a href=\"".$sitename."/cgi-bin/adminuserlist.pl?act=delete&id=$id\">Удалить</a></td></tr>";

				}
				print "</table>";
				print "<a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a>";

			    }
			    print $q->end_html();
		    }
		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('adminlogin.pl')
	}
