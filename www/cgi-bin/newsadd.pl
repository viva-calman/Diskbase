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

#Вывод краткого списка последних добавленых новостей
sub lastnews {
    my $sth=$dbh->prepare("select data,header from news order by id desc limit 10");
    $sth->execute() or die $DBI::errstr;
    print "<table class=\"maintable\" cellspacing=0 border=1 align=center>";
    while (my($data,$header)=$sth->fetchrow_array())
    {
	print "<tr><td>$data</td><td>$header</td></tr>";
    }
    print "</table>";
    $sth->finish();
}


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
		    print $q->start_html(-style=>'../site.css',-title=>'Управление новостями');
		    open (ADMINHEAD,"adminhead.inc");
		    while (<ADMINHEAD>)
		    {
			print $_;
		    }
		    close (ADMINHEAD);
		    my $act=$q->param('act');
		    switch ($act)
		    {
			case 'add'
			{
			    #Добавление новости	
			    print "<b>Добавление новости</b>";
			    print "<form action=\"newsadd.pl\" method=\"post\">";
			    print "<table align=center class=\"maintable\" border=1 cellspacing=0>";
			    print "<tr><td>Заголовок:</td><td align=left><input type=\"text\" name=\"header\" class=\"adminedit\" size=48></td></tr>";
			    print "<tr><td>Текст новости:</td><td><textarea rows=5 cols=40 class=\"adminedit\" name=\"body\"></textarea></td></tr>";
			    print "<tr><td colspan=2><input type=\"submit\" value=\"Добавить\" ><input type=\"reset\" value=\"Очистить\"></td></tr>";
			    print "<tr><td></td><td></td></tr>";

			    print "</table>";
			    print "<input type=\"hidden\" name=\"act\" value=\"submit\">";
			    print "<input type=\"hidden\" name=\"do\" value=\"add\">";
			    print "</form>";
			    print "<a href=\"".$sitename."/cgi-bin/newsadd.pl\">Вернуться к управлению новостями</a><br>";

			}
			case 'submit'
			{
			    #Подтверждение	
			    my $header=$q->param('header');
			    my $body=$q->param('body');
			    my $id=$q->param('id');
			    my $do=$q->param('do');
			    my $data=$q->param('data');
			    my $message;
			    switch ($do)
			    {    
			    case 'add'
				{
				    $sth=$dbh->prepare("insert into news (data,header,body) values ('$now','$header','$body')");
				    $message="Новость добавлена";
				}
			    case 'edit'
				{
				    $sth=$dbh->prepare("update news set header='$header',body='$body',data='$data' where id=$id");
				    $message="Новость отредактирована";
				}
			    case 'delete'
				{
				    $sth=$dbh->prepare("delete from news where id=$id");
				    $message="Новость удалена";
				}
			    }
			    if ($do)
			    {
				$sth->execute() or die $DBI::errstr;
			    }
			    print "$message.<br><a href=\"".$sitename."/cgi-bin/newsadd.pl\">Вернуться к управлению новостями</a><br>";
			    $sth->finish();
			}
			case 'delete'
			{
			    my $delid=$q->param('id');
			    print "<b>Вы уверены в том, что хотите удалить эту новость?</b>";
			    $sth=$dbh->prepare("select * from news where id=$delid");
			    $sth->execute() or die $DBI::errstr;
			    my ($id,$data,$header,$body)=$sth->fetchrow_array();
			    print "<table class=\"maintable\" border=1 cellspasing=0 align=center width=60%>";
			    print "<tr><td>Дата добавления:</td><td>$data</td></tr>";
			    print "<tr><td>Заголовок:</td><td>$header</td></tr>";
			    print "<tr><td>Текст новости:</td><td>$body</td></tr>";
			    print "<tr><td colspan=2><table border=0 align=center><tr><td align=right>";
			    print "<form action=\"newsadd.pl\" method=\"post\"><input type=\"hidden\" name=\"act\" value=\"submit\"><input type=\"hidden\" name=\"do\" value=\"delete\"><input type=\"hidden\" name=\"id\" value=\"$delid\"><input type=submit value=\"Удалить\"></form>";
			    print "</td><td align=left>";
			    print "<form action=\"newsadd.pl\" method=\"post\"><input type=submit value=\"Отмена\"><input type=\"hidden\" name=\"act\" value=\"list\"></form>";
			    print "</tr></table></td></tr>";
			    print "</table>";
			    $sth->finish();
			}
			case 'edit'
			{
			    my $edid=$q->param('id');
			    $sth=$dbh->prepare("select * from news where id=$edid");
			    $sth->execute() or die $DBI::errstr;
			    my($id,$data,$header,$body)=$sth->fetchrow_array();
			    print "<b>Редактирование новости</b>";
			    print "<form action=\"newsadd.pl\" method=\"post\">";
			    print "<table class=\"maintable\" sellspacing=0 border=1 align=center>";
			    print "<tr><td>Дата добавления:</td><td>$data</td></tr>";
			    print "<tr><td>Заголовок:</td><td align=left><input type=\"text\" class=\"adminedit\" value=$header name=\"header\" size=48></td></tr>";
			    print "<tr><td>Текст сообщения:</td><td><textarea class=\"adminedit\" name=\"body\" rows=5 cols=40>$body</textarea></td></tr>";
			    print "<tr><td colspan=2><input type=\"submit\" value=\"Сохранить\"><input type=\"reset\" value=\"Очистить\"></td></tr>";
			    print "<input type=\"hidden\" name=\"act\" value=\"submit\" >";
			    print "<input type=\"hidden\" name=\"do\" value=\"edit\">";
			    print "<input type=\"hidden\" name=\"id\" value=\"$id\">";
			    print "<input type=\"hidden\" name=\"data\" value=\"$data\">";
			    print "</table></form>";
			    print "<a href=\"".$sitename."/cgi-bin/newsadd.pl\">Вернуться к управлению новостями</a><br>";
			    $sth->finish();
			}
			case 'list'
			{
			    #Вывод списка новостей постранично	
			    my $page;
			    my @ids;
			    my $count=0;
			    #получение количества записей
				$sth=$dbh->prepare("select id from news order by id desc");
				$sth->execute() or die $DBI::errstr;
				while ((my $idl)=$sth->fetchrow_array())
				{
				    $ids[$count]=$idl;
				    $count++;
				}
			    #Если переменная $page не определена, приравниваем ее единице
			    if(!($page=$q->param('page')))
			    {
				$page=1;
			    }
			    
			    my $minlimit;
			    my $maxlimit;
			    my $minlim=$page*10;
			    my $maxlim=($page-1)*10;
			    if ($minlim>$count)
			    {
				$minlim=$count;
			    }
			    $minlimit=$ids[$minlim];
			    $maxlimit=$ids[$maxlim];
			    print "<b>список новостей</b>"; 
			    print "<table class=\"maintable\" border=1 cellspacing=0 align=center width=60%>";
			    $sth=$dbh->prepare("select * from news where id >'$minlimit' and id <='$maxlimit' order by id desc");
			    $sth->execute() or die $DBI::errstr;
			    my $lastid;
			    while (my ($id,$date,$header,$body)=$sth->fetchrow_array())
			    {
				print "<tr><td><table border=0 cellspacing=0 width=100%>";
				print "<tr><td align=left width=35% ><span class=\"remarks\" ><b>Добавлено:</b> $date</span></td><td align=left><h4>$header</h4></td>";
				print "<td align=right width=10%><span class=\"remarks\"><a href=\"".$sitename."/cgi-bin/newsadd.pl?act=edit&id=$id\">Редактировать</a></span></td>";
				print "<td align=right width=5%><span class=\"remarks\"><a href=\"".$sitename."/cgi-bin/newsadd.pl?act=delete&id=$id\">Удалить</a></span></td></tr>";
				print "<tr><td colspan=4 align=left>$body</td></tr></table>";
				print "</td><tr>";
				$lastid=$id;
			    }
			    print "</table><span class=\"remarks\">";
			    print "<table align=center border=0>";
			    #Создание ссылок перехода по страницам.
			    #Ссылка на предыдущую страницу
			    print "<tr><td>";
			    if($page>1)
			    {
				my $prewpage=$page-1;
				print "<a href=\"".$sitename."/cgi-bin/newsadd.pl?act=list&page=$prewpage\">Предыдущая</a>"
			    }
			    print "</td><td><b>страница $page</b></td><td>";
			    if ($minlim<$count)
			    {
				my $nextpage=$page+1;
				print "<a href=\"".$sitename."/cgi-bin/newsadd.pl?act=list&page=$nextpage\">Следующая</a>";
			    }
			    print "</td><td>";
			    print "</table></span>";
			    print "<br><a href=\"".$sitename."/cgi-bin/newsadd.pl\">Вернуться к управлению новостями</a>";

			}
			else
			{
			    #Выбор действия, показ последних добавленных новостей
			    print "<b>Управление новостями</b>";
			    print "<table class=\"maintable\" cellspacing=0 border=1 align=center>";
			    print "<tr><td><b>Последние добавленные новости</b></td><td><b>Действия</b></td></tr>";
			    print "<tr><td>";
			    #вызов функции показа последних новостей
			    &lastnews();
			    print "</td><td valign=top>";
			    print "<table>";
	    
			    print "<tr><td align=center><a href=\"".$sitename."/cgi-bin/newsadd.pl?act=list\">Список новостей</a></td></tr>";
			    print "<tr><td align=center><a href=\"".$sitename."/cgi-bin/newsadd.pl?act=add\">Добавление новости</a></td></tr>";
#			    print "<tr><td><a href=\"".$sitename."\"></a></td></tr>";
#			    print "<tr><td><a href=\"".$sitename."\"></a></td></tr>";
			    print "</table>";
			    print "</td></tr>";
			    print "</table>";
			}
		    }
		    print "<br><a href=\"".$sitename."/cgi-bin/admincp.pl\">Вернуться в панель управления</a>";
		    print "</div></div>";
		    print $q->end_html();
		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('adminlogin.pl')
	}
