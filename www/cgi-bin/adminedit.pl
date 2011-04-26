#!/usr/bin/perl -w
#
#Редактирование диска
#
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
		    print $q->start_html(-style=>'../site.css', -title=>'Редактирование записи диска');
		    my $act=$q->param('act');
		    switch ($act) 
		    {
			case 'edit'
			{
			    open (AHEADER,"adminhead.inc");
			    while (<AHEADER>)
			    {
				    print $_;
			    }
			    close (AHEADER);
			    my $editid=$q->param('id');
			    my $title=$q->param('title');
			    my $lable=$q->param('lable');
			    my $type=$q->param('type');
			    my $year=$q->param('year');
			    my $number=$q->param('number');
			    my $description=$q->param('description');
			    my $autorun=$q->param('autorun');
			    my $errorstate=0;
			    my $errormessage="Недопустимое значение поля";
			    my ($bg1,$bg2,$bg3)='';
			    #Делаем проверку значений
			    if ($year=~/\D/)
			    {
				$errorstate=1;
				$bg2="bgcolor=#ff0000";
			    }
			    if ($number=~/\D/)
			    {
				$errorstate=1;
				$bg3="bgcolor=#ff0000";
			    }
			    #В случае ошибки выводим форму

			    if ($errorstate == 1)
			    {
				$sth=$dbh->prepare("select * from type");
				$sth->execute();
			        my %lablelist;
				my %typelist;
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
				if($lable==5)
				{
				    my $tabtitle=$title;
				}
				else
				{
				    my $tabtitle=$lablelist{$lable};
				}
				print "<h3>Редактирование данных о диске</h3>";
				print "<h3>$errormessage</h3>";
				print "<form action=\"adminedit.pl\" method=\"post\">";
				print "<table class=\"maintable\" cellspacing=0 border=1 align=\"center\">";
				print "<tr><td >Название</td><td align=\"left\"><input type=\"text\" name=\"title\" value=\"$title\" class=\"adminedit\"></td></tr>";	
				print "<tr><td>Издание</td><td align=\"left\"><select name=\"lable\" class=\"adminedit\"><option value=0></option>";
				while (my ($labid,$lab)=each %lablelist)
				{
				    if($labid==$lable)
				    {	
					print "<option selected value=\"$labid\">".$lab."</option>";
				    }
				    else
				    {
					print "<option value=\"$labid\">".$lab."</option>";
				    }
				}
				print "</select></td></tr>";	
				print "<tr><td>Тип</td><td align=\"left\"><select name=\"type\" class=\"adminedit\"><option value=0></option>";
				while (my ($typid,$typ)= each %typelist)
				{
				    if($typid==$type)
				    {
					print "<option selected value=\"$typid\">".$typ."</option>";
				    }
				    else
				    {
					print "<option value=\"$typid\">".$typ."</option>";
				    }
				}
				print "</select></td></tr>";	
				print "<tr><td $bg2>Год издания</td><td align=\"left\"><input type=\"text\" name=\"year\" value=\"$year\" class=\"adminedit\"></td></tr>";	
				print "<tr><td $bg3>Номер</td><td align=\"left\"><input type=\"text\" name=\"number\" value=\"$number\" class=\"adminedit\"></td></tr>";	
				print "<tr><td>Описание</td><td align=\"left\"><textarea rows=5 cols=40 name=\"description\" class=\"adminedit\">".$description."</textarea></td></tr>";	
				print "<tr><td>Путь к оболочке</td><td align=\"left\"><input type=\"text\" name=\"autorun\" value=\"$autorun\" class=\"adminedit\"></td></tr>";	
				print "<tr><td colspan=2><input type=\"submit\" value=\"Изменить\"></td></tr>";
				print "<input type=\"hidden\" value=\"edit\" name=\"act\">";
				print "<input type=\"hidden\" value=\"$editid\" name=\"id\">";
				print "</table></form>";
				print "</div></div>";
				print $q->end_html();
			    }
			    else
			    {
			    my $sth=$dbh->prepare("update imgs set title='$title',lable='$lable',type='$type',year=$year,number=$number, description='$description',autorun='$autorun' where id=$editid");
			    $sth->execute() or die $DBI::errstr;
			    print "Редактирование успешно. Нажмите для перехода <a href=\"".$sitename."/cgi-bin/admincat.pl\">в каталог</a> или <a href=\"".$sitename."/cgi-bin/admincp.pl\">в панель управления</a>";
			    print $q->end_html();
			    }
			}
			else
			{
			    open (AHEADER,"adminhead.inc");
			    while (<AHEADER>)
			    {
				    print $_;
		    
			    }
			    close (AHEADER);
			    print "<b>редактирование данных о диске</b>";
			    my $editid=$q->param('id');
			    $sth=$dbh->prepare("select * from imgs where id=$editid");
			    $sth->execute();
			    my($id,$itype,$title,$lable,$year,$number,$description,$createdate,$autorun)=$sth->fetchrow_array();
			    $sth=$dbh->prepare("select * from type");
			    $sth->execute();
			    my %lablelist;
			    my %typelist;
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
			    if($lable==5)
			    {
				my $tabtitle=$title;
			    }
			    else
			    {
				my $tabtitle=$lablelist{$lable};
			    }
			    print "<form action=\"adminedit.pl\" method=\"post\">";
			    print "<table class=\"maintable\" cellspacing=0 border=1 align=\"center\">";
			    print "<tr><td>Название</td><td align=\"left\"><input type=\"text\" name=\"title\" value=\"$title\" class=\"adminedit\"></td></tr>";	
			    print "<tr><td>Издание</td><td align=\"left\"><select name=\"lable\" class=\"adminedit\"><option value=0></option>";
			    while (my ($labid,$lab)=each %lablelist)
			    {
				if($labid==$lable)
				{	
				    print "<option selected value=\"$labid\">".$lab."</option>";
				}
				else
				{
				    print "<option value=\"$labid\">".$lab."</option>";
				}
			    }
			    print "</select></td></tr>";	
			    print "<tr><td>Тип</td><td align=\"left\"><select name=\"type\" class=\"adminedit\"><option value=0></option>";
			    while (my ($typid,$typ)= each %typelist)
			    {
				if($typid==$itype)
				{
				    print "<option selected value=\"$typid\">".$typ."</option>";
				}
				else
				{
				    print "<option value=\"$typid\">".$typ."</option>";
				}
			    }
			    print "</select></td></tr>";	
			    print "<tr><td>Год издания</td><td align=\"left\"><input type=\"text\" name=\"year\" value=\"$year\" class=\"adminedit\"></td></tr>";	
			    print "<tr><td>Номер</td><td align=\"left\"><input type=\"text\" name=\"number\" value=\"$number\" class=\"adminedit\"></td></tr>";	
			    print "<tr><td>Описание</td><td align=\"left\"><textarea rows=5 cols=40 name=\"description\" class=\"adminedit\">".$description."</textarea></td></tr>";	
			    print "<tr><td>Путь к оболочке</td><td align=\"left\"><input type=\"text\" name=\"autorun\" value=\"$autorun\" class=\"adminedit\"></td></tr>";	
			    print "<tr><td colspan=2><input type=\"submit\" value=\"Изменить\"></td></tr>";
			    print "<input type=\"hidden\" value=\"edit\" name=\"act\">";
			    print "<input type=\"hidden\" value=\"$editid\" name=\"id\">";
			    print "</table></form>";
			    print "</div></div>";
			    print $q->end_html();
			}
		    }	
		}
	}	
else
	{
	#
	#Если кукисов нет - редирект
	print $q->redirect('adminlogin.pl');
	}
