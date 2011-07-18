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
#Вывод имени образа
sub disk {
	my $diskid=$_[0];
	my %typelist;
	my %lablelist;
	my $last_disk="";
	my $sth=$dbh->prepare("select imgs.title,imgs.lable,imgs.number,imgs.year from imgs where imgs.id=$diskid");
	$sth->execute();
	my($title,$lableid,$num,$year)=$sth->fetchrow_array();
	##
	#Формируем хеши названий
	$sth=$dbh->prepare("select * from lable");
	$sth->execute();
	while(my($lableid,$lable)=$sth->fetchrow_array())
	{
	    $lablelist{$lableid}=$lable;
	}
	if($lableid==5)
	{
	    $last_disk=$last_disk.$title."  ";
	}
	else
	{
	    $last_disk=$last_disk.$lablelist{$lableid}
	}
	if($num)
	{
	    $last_disk=$last_disk." номер ".$num;
	}
	if($year)
	{
	    $last_disk=$last_disk." за ".$year."  год.</span>";
	}
	print $last_disk;
};


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
		    print $q->start_html(-title=>'Активные сессии пользователей', -style=>'../site.css');
		    open (ADMINHEAD,"adminhead.inc");
		    while(<ADMINHEAD>)
		    {
			print $_;
		    }
		    close(ADMINHEAD);
		    my $act=$q->param('act');
		    switch($act)
		    {
			case 'stop'
			{
			    my $id=$q->param('id');
			    $sth=$dbh->prepare("delete from usersession where id=$id");
			    $sth->execute() or die $DBI::errstr;
			    print "<b>Активные пользователи</b><br>Сессия остановлена";
			}
			else
			{
			    print "<b>Активные пользователи</b>";
			}
		    }
			    $sth=$dbh->prepare("select users.username,usersession.id,usersession.sessionstart,usersession.diskid from users,usersession where usersession.userid=users.id order by usersession.sessionstart");
			    $sth->execute() or die $DBI::errstr; 
			    print "<table cellspacing=0 class=\"maintable\" align=\"center\" border=1>";
			    print "<tr><td><b>Имя пользователя</b></td><td><b>Время начала сессии</b></td><td><b>Используемый образ</b></td><td><b>Действие</b></td></tr>";
			    while (my($user,$id,$sessionstart,$diskid)=$sth->fetchrow_array())
			    {
				print "<tr><td>$user</td><td>$sessionstart</td><td>";
				&disk($diskid);
				print "</td><td><a href=\"".$sitename."/cgi-bin/adminusers.pl?act=stop&id=$id\">Прервать сессию</a></td></tr>";
			    }
			    $sth->finish();
			    print "</table>";
			    print "<a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a>";	
		    
		    print $q->end_html();
		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('adminlogin.pl')
	}
