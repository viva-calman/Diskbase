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
# Вывод текущего смонтированого образа
#
sub current_img {
	my $sesskey=$_[0];
	my %typelist;
	my %lablelist;
	my $last_disk="<span class=\"remarks\">Сейчас смонтирован: ";
	my $sth=$dbh->prepare("select imgs.title,imgs.lable,imgs.number,imgs.year from imgs,usersession where usersession.sessionkey='$sesskey' and usersession.diskid=imgs.id");
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
if ($cookies{'sessionkey'})
	{
	#
	#Проверка существования кукисов
	my $sesskey=$cookies{'sessionkey'}->value;
	my $sth=$dbh->prepare("select id,sessiontime from usersession where sessionkey='$sesskey'");
	$sth->execute() or die $DBI::errstr;
	my ($sessid,$sesstime)=$sth->fetchrow_array();
	if ($sessid eq '' or ($sesslong-$sesstime)>$sessionlong)
		{
		#	
		#Если кукисы просрочены - редирект
		$sth=$dbh->prepare("delete from usersession where sessionkey='$sesskey'");
		$sth->execute();
		$sth->finish();
		print $q->redirect('login.pl');
		}
	else
		{
		#Код страницы
		    my $sth=$dbh->prepare("update usersession set sessiontime=$sesslong where id=$sessid");
		    $sth->execute();
		    print $q->header(-charset=>'utf-8');
		    print $q->start_html(-title=>'Управление монитрованием',-style=>'../site.css');
		    my $act=$q->param('act');
		    my $id=$q->param('id');
		    my $autorun=$q->param('autorun');
		    open(CATEL,"catel.inc");
		    while(<CATEL>)
		    {
			print $_;
		    }
		    close (CATEL);
		    print "<table border=0 sellspacing=0 align=center width=100%><tr><td align=left><a href=\"".$sitename."/\">На главную</a>  ";
		    print "<a href=\"".$sitename."/cgi-bin/cat.pl\">Вернуться в каталог</a></td>";
		    print "<td align=right><a href=\"".$sitename."/cgi-bin/logout.pl\">Выход из системы</a></td></tr></table>";
		    print "</div><div class=\"text\">";
		    $sth=$dbh->prepare("select userid from usersession where id=$sessid");
		    $sth->execute() or die $DBI::errstr ;
		    my $userid=$sth->fetchrow_array();
		    $sth=$dbh->prepare("select username from users where id=$userid");
		    $sth->execute() or die $DBI::errstr;
		    my $username=$sth->fetchrow_array();

		    switch($act)
		    {
			case 'mount'
			{
			    	
			    #Действия при монтировании нового образа
			    print "<b>Монтирование образа</b></br>";
			    $sth=$dbh->prepare("update usersession set diskid=$id where id=$sessid");
			    $sth->execute() or die $DBI::errstr;
			    my $mount=`./mount.sh $username $id`;
			    print "образ смонтирован";
			    print "<br><a href=\"".$sitename."/cgi-bin/cat.pl\">Вернуться в каталог</a>"
			}
			case 'umount'
			{
			    my $umount=`rm /home/$username/disk && ln -s /home/$username/help /home/$username/disk`;					$sth=$dbh->prepare("update users set lastdisk='NULL' where id=$userid");
			    $sth->execute() or die $DBI::errstr;
			    $sth=$dbh->prepare("update usersession set diskid='NULL' where id=$sessid");
			    $sth->execute() or die $DBI::errstr;
			    print "Образ отмонтирован<br>";
			    print "<a href=\"".$sitename."/cgi-bin/cat.pl\">Вернуться в каталог</a>";
			}
			else
			{
			    #Управление монтированием
			    print "<b>Сейчас смонтирован:</b><br>";
			    &current_img($sesskey);
			    print "<form action=\"mount.pl\" method=\"post\">";
			    print "<input type=\"hidden\" name=\"act\" value=\"umount\">";
			    print "<input type=\"submit\" value=\"Размонтировать\">";
			    print "</form>";
			}
		    
		    }
		    print "</div></div>";
		    print $q->end_html();
		    $sth->finish();


		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('login.pl')
	}
