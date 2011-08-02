#!/usr/bin/perl -w

use strict;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use CGI;
use CGI::Cookie;
use Switch;
use POSIX qw(strftime);

#
#Определяем переменные подключения к БД, имени хоста и т.д.
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
#Процедурка вывода текущего образа
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
	if($lableid)
	{
	    print $last_disk."<a href=\"".$sitename."/cgi-bin/mount.pl\">размонтировать</a>";
	}
};
#
#Процедурка Вывода селектов, и прочего
sub menugen {
	my $sesskey=$_[0];
	print "<table cellspacing=0 border=0><tr><td>Тип издания:</td><td><select name=\"stype\" class=\"menu1\">";
	print "<option value=0></option>";
	my $sth=$dbh->prepare("select * from type");
	$sth->execute();
	while (my($typeid,$type)=$sth->fetchrow_array())
	{
		print "<option value=".$typeid.">".$type."</option>";
	}
	print "</select></td><td>Издание:</td><td><select name=\"lable\" class=\"menu1\">";
	print "<option value=0></option>";
	#
	#Селект выбора издания
	$sth=$dbh->prepare("select * from lable");
	$sth->execute();
	my %lablelist;
	while (my($lableid,$lable)=$sth->fetchrow_array())
	{
		print "<option value=".$lableid.">".$lable."</option>";
	}
	print "</select></td><td>Ключевые слова:</td><td>";
	##
	#Вывод поля поиска
	print "<input type=\"text\" name=\"searchstr\" class=\"menu1\">";
	print "<input type=\"hidden\" name=\"act\" value=\"search\"><input type=\"submit\" value=\"Найти!\">";
	print "</td></tr></table></form></span>";
	&current_img($sesskey);
	print "</div><div class=\"sidemenu\"></div><div class=\"text\">";
};
#
#Запрос кукисов
my %cookies=fetch CGI::Cookie;
if ($cookies{'sessionkey'})
	{
	#
	#Проверка времени сессии
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
		#Вывод заголовков
		    my $sth=$dbh->prepare("update usersession set sessiontime=$sesslong where id=$sessid");
		    $sth->execute();
		    print $q->header(-charset=>'utf-8');
		    print $q->start_html(-style=>'../site.css',-title=>'Каталог дисков');
		    my $act=$q->param('act');
		    #
		    #Выводим хедер
		    open (USERHEAD, "userhead.inc");
		    while(<USERHEAD>)
		    {
			print $_;
		    }
		    close(USERHEAD);
		    switch ($act)
		    {
			#
			#Выбор действия - поиск
			case 'search'
			{   
			    my $order;	
			    my $sort=$q->param('sort');
			    switch ($sort)
			    {
				    case 1
				    {
					$order="lable";
				    }
				    case 2
				    {
					$order="type";
				    }
				    case 3
				    {
					$order="year";
				    }
				    case 4
				    {
					$order="createdate";
				    }
				    else
				    {
					$order="lable";
				    }
				    
			    }
			    my $labl=$q->param('lable');
			    my $typ=$q->param('stype');
			    my $keyword=$q->param('searchstr');
			    #
			    #
			    #Тут будет маленькая процедурка проверки строки поиска на вшивость
			    $keyword=~s/\'/\\\'/g;
			    $keyword=~s/\`/\\\`/g;
			    #   
			    #
			    #Вывод таблицы заголовка, рисуем селекты
			    &menugen($sesskey);
			    ##
			    #Создаем поисковый запрос
			    my %typelist;
			    my %lablelist;
			    my $search_query="select * from imgs where description like '%$keyword%'";
			    if($labl != 0)
			    {
				$search_query=$search_query."and lable=$labl ";
			    }
			    if($typ != 0)
			    {
				$search_query=$search_query."and type=$typ";
			    }
			    #
			    #Формируем хеши названий
			    my $sth=$dbh->prepare("select * from type");
			    $sth->execute();
			    while(my($typeid,$type)=$sth->fetchrow_array())
			    {
				$typelist{$typeid}=$type;
			    }
			    
			    ##
			    #Формируем хеши названий
			    $sth=$dbh->prepare("select * from lable");
			    $sth->execute();
			    while(my($lableid,$lable)=$sth->fetchrow_array())
			    {
				$lablelist{$lableid}=$lable;
			    }
			    #
			    #Окончательно формируем строку запроса и делаем выборку
			    $search_query=$search_query." order by $order desc";
			    $sth=$dbh->prepare("$search_query");
			    $sth->execute() or die $sth->errstr;
			    #
			    #Рисуем таблицу
			    print "<table align=\"center\" cellspacing=0 border=4 class=\"maintable\">"; 
			    print "<tr><td><a href=\"".$sitename."/cgi-bin/cat.pl?sort=1&act=search&lable=".$labl."&stype=".$typ."&searchstr=".$keyword."\">Название</a></td>";
			    print "<td><a href=\"".$sitename."/cgi-bin/cat.pl?sort=2&act=search&lable=".$labl."&stype=".$typ."&searchstr=".$keyword."\">Тип</a></td>";
			    print "<td><a href=\"".$sitename."/cgi-bin/cat.pl?sort=3&act=search&lable=".$labl."&stype=".$typ."&searchstr=".$keyword."\">Год издания</a></td><td>Номер</td>";
			    print "<td><a href=\"".$sitename."/cgi-bin/cat.pl?sort=4&act=search&lable=".$labl."&stype=".$typ."&searchstr=".$keyword."\">Добавлено</a></td><td>Описание</td></tr>";
			    ##
			    my $tabtitle;
			    while(my($id,$itype,$title,$lable,$year,$number,$description,$createdate,$autorun)=$sth->fetchrow_array())
			    {
				$description=substr($description,0,100)."...";  
				if($lable==5)
				{
				    $tabtitle=$title;
				}
				else
				{
				    $tabtitle=$lablelist{$lable};
				}
				print "<tr><td>$tabtitle</td><td>".$typelist{$itype}."</td><td>$year</td><td>$number</td><td>$createdate</td><td>$description";
				print "<a href=\"".$sitename."/cgi-bin/catel.pl?id=$id\">Подробнее</a></td></tr>";

			    }
			    $sth->finish();
			    print "</table></div>"

			}
			#
			#Действие - вывод всех результатов
			else
			{
			    #
			    #Порядок сортировки
			    my $order;	
			    my $sort=$q->param('sort');
			    switch ($sort)
			    {
				    case 1
				    {
					$order="lable";
				    }
				    case 2
				    {
					$order="type";
				    }
				    case 3
				    {
					$order="year";
				    }
				    case 4
				    {
					$order="createdate";
				    }
				    else
				    {
					$order="lable";
				    }
				    
			    }
			    #
			    #Рисуем таблицу звголовка
			    &menugen($sesskey);			    
			    ##
			    #Формируем хеши названий
			    my %typelist;
			    my %lablelist;
			    my $sth=$dbh->prepare("select * from type");
			    $sth->execute();
			    while(my($typeid,$type)=$sth->fetchrow_array())
			    {
				$typelist{$typeid}=$type;
			    }
			    
			    ##
			    $sth=$dbh->prepare("select * from lable");
			    $sth->execute();
			    while(my($lableid,$lable)=$sth->fetchrow_array())
			    {
				$lablelist{$lableid}=$lable;
			    }
			    #
			    #Делаем выборку
			    $sth=$dbh->prepare("select * from imgs order by $order desc");
			    $sth->execute();

			    print "<table align=\"center\" cellspacing=0 border=4 class=\"maintable\">"; 
			    print "<tr><td><a href=\"".$sitename."/cgi-bin/cat.pl?sort=1\">Название</a>";
			    print "</td><td><a href=\"".$sitename."/cgi-bin/cat.pl?sort=2\">Тип</a></td>";
			    print "<td><a href=\"".$sitename."/cgi-bin/cat.pl?sort=3\">Год издания</td>";
			    print "<td>Номер</td><td><a href=\"".$sitename."/cgi-bin/cat.pl?sort=4\">Добавлено</td>";
			    print "<td>Описание</td></tr>";
			    ##
			    my $tabtitle;
			    #
			    #Отрисовываем таблицу
			    while(my($id,$itype,$title,$lable,$year,$number,$description,$createdate,$autorun)=$sth->fetchrow_array())
			    {
				$description=substr($description,0,100)."...";
				if($lable==5)
				{
				    $tabtitle=$title;
				}
				else
				{
				    $tabtitle=$lablelist{$lable};
				}
				print "<tr><td>$tabtitle</td><td>".$typelist{$itype}."</td><td>$year</td><td>$number</td><td>$createdate</td><td>$description ";
				print "<a href=\"".$sitename."/cgi-bin/catel.pl?id=$id\">Подробнее</a></td></tr>";

			    }
			    $sth->finish();
			    print "</table></div>";
			    print "<a href=\"".$sitename."\">На главную</a>";
			}
		    }
		    print $q->end_html;
		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	#my $q=new CGI;
	print $q->redirect('login.pl')
	}
