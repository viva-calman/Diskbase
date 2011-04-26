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
#Вывод формы
sub form{
    my $errmessg=$_[0];
    print "<h4>".$errmessg."</h4>";
    print "<form action=\"adminpasschange.pl\" method=\"post\">";
    print "<table cellspacing=0 border=1 class=\"maintable\" align=\"center\">";
    print "<tr><td>Введите новый пароль</td><td><input type=\"password\" name=\"passwd\" class=\"adminedit\"></td></tr>";
    print "<tr><td>Повторите пароль</td><td><input type=\"password\" name=\"repasswd\" class=\"adminedit\"></td></tr>";
    print "<input type=\"hidden\" value=\"change\" name=\"act\">";
    print "<tr><td colspan=2><input type=\"submit\" value=\"Изменить\"></td></tr>";
    print "<tr><td colspan=2><a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернутьсяв панель управления</a></td></tr>";
    print "</table></form>";
}
#
#Запрос кукисов
my %cookies=fetch CGI::Cookie;
if ($cookies{'asessionkey'})
	{
	#
	#Проверка существования кукисов
	my $sesskey=$cookies{'asessionkey'}->value;
	my $sth=$dbh->prepare("select id,userid,sessiontime from adminsession where sessionkey='$sesskey'");
	$sth->execute();
	my ($sessid,$userid,$sesstime)=$sth->fetchrow_array();
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
		print $q->start_html(-style=>'../site.css',-title=>'Смена пароля администратора');
		open (ADMINHEAD, "adminhead.inc");
		while (<ADMINHEAD>)
		{
		    print $_;
		}
		close (ADMINHEAD);
		if ($userid != 1)
		{
		    print "<h3>Вы не обладаете достаточными правами для совершения этого действия</h3><br><a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться</a>";
		}
		else
		{
		    my $act=$q->param('act');	
		    if ($act eq 'change')
		    {
			    my $passwd=$q->param('passwd');
			    my $repasswd=$q->param('repasswd');
			    my $eror='';
			    my $erst=0;
			    if ($passwd ne $repasswd)
			    {
				$eror='Пароли не совпадают';
				$erst=1;
			    }
			    if (length($passwd)<8)
			    {
				$eror=$eror.'<br>Пароль должен быть длиннее семи символов';
				$erst=1;
			    }
			    if($erst==1)
			    {
				&form($eror);
			    }
			    else
			    {
				my $password_hash=md5_hex($passwd);
				$sth=$dbh->prepare("update admins set password='$password_hash' where id=1");
				$sth->execute();
				print "<h3>Пароль изменен</h3>";
				print "<a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a>";
			    }
		    }
		    else
		    {
		    	&form();	
		    }
		}
		print $q->end_html;
	    }
	    	
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('adminlogin.pl')
	}
