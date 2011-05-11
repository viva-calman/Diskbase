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
#Процедура отрисовки таблицы
sub tabledraw {
    print "<table class=\"maintable\" border=1 cellspacing=0 align=center>";
    print "<tr><td><b>Название</b></td><td><b>Записей</b></td><td><b>Действие</b></td></tr>";
    my $sth=$dbh->prepare("select lable.id,lable.lable,count(imgs.id) from lable left outer join imgs on lable.id=imgs.lable group by lable.id");
    $sth->execute() or die $DBI::errstr;
    my $link;
    while(my($id,$lable,$count)=$sth->fetchrow_array())
    {
	if($id!=5)
	{
		if ($count==0)
		{
			$link="<a href=\"".$sitename."/cgi-bin/admaddlable.pl?act=remove&id=$id\">Удалить</a>";
		}
		else
		{
			$link="Удаление невозможно";
		}
		print "<tr><td>$lable</td><td>$count</td><td>$link</td></tr>";
	 
	}
	else
	{
		print "<tr><td>$lable</td><td>$count</td><td>-</td></tr>"
	}
    }
    print "<form action=\"admaddlable.pl\" method=\"post\">";
    print "<tr><td align colspan=3><input type=\"text\" class=\"adminedit\" name=\"lable\" ><input type=\"submit\" value=\"Добавить\"></td></tr>";
    print "<input type=\"hidden\" value=\"add\" name=\"act\">";
    print "</form></table>";
    print "<a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a>";
    $sth->finish();
}


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
		    print $q->start_html(-title=>'Редактирование списка изданий',-style=>'../site.css');
		    open (ADMINHEAD,"adminhead.inc");
		    while (<ADMINHEAD>)
		    {
			    print $_;
		    }
		    close ADMINHEAD;
		    print "<b>Изменение списка изданий</b><br><span class=\"remarks\">Удалить можно только те издания, образов которых нет в базе</span><br>";
		    my $act=$q->param('act');
		    switch ($act)
		    {
			case 'add'
			{
			    my $addlable=$q->param('lable');
			    $sth=$dbh->prepare("select id from lable where lable='$addlable'");			    
			    $sth->execute() or die $DBI::errstr;
			    if ((my $id=$sth->fetchrow_array()) == '')
			    {
				$sth=$dbh->prepare("insert into lable (lable) values ('$addlable')");
				$sth->execute() or die $DBI::errstr;
				print "Запись добавлена<br>";
				&tabledraw();
			    }
			    else
			    {
				print "Такая запись уже существует<br>";
				&tabledraw();
			    }

			}
			case 'remove'
			{
				my $rmid=$q->param('id');
				if ($rmid!=5)
				{
				    $sth=$dbh->prepare("delete from lable where id=$rmid");
				    $sth->execute() or die $DBI::errstr;
				    print "Запись удалена<br>";
				    &tabledraw();
				}
				else
				{
					print "Удалить данную категорию невозможно";
					&tabledraw();
				}
			}
			else
			{
			    &tabledraw();
			    
			}
		    }
		    print $q->end_html();

		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('adminlogin.pl')
	}
