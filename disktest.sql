create table type(
	id int NOT NULL auto_increment,
	type varchar(255),
	primary key (id)
	) charset=utf8;

create table lable(
	id int not NULL auto_increment,
	lable varchar(255),
	primary key (id)
	)charset=utf8;

create table imgs(
	id int NOT NULL auto_increment,
	type int,
	title varchar(255),
	lable int,
	year int,
	number int,
	description text,
	createdate timestamp,
	autorun varchar(255),
	foreign key (type) references type(id),
	foreign key (lable) references lable(id),
	primary key (id)
	) charset=utf8;
	


create table users(
	id int NOT NULL auto_increment,
	username varchar(32) ,
	password varchar(255),
	createdate datetime,	
	status smallint,
	lastdisk int,
	lastvisit timestamp,
	primary key (id),
	foreign key (lastdisk) references imgs(id)
	) charset=utf8;
	


create table usersession (
	id int NOT NULL auto_increment,
	userid int,
	sessionkey varchar(255),
	sessionstart datetime,
	sessiontime int, 
	diskid int,
	foreign key (diskid) references imgs(id),
	primary key (id)
	) charset=utf8;
	
insert into usersession (userid,sessionkey,sessionstart,sessiontime) values (1,'safsasfwsasdfsaf','2011-02-27 12:00:00',1212121212);

create table admins(
	id int NOT NULL auto_increment,
	username varchar(32) ,
	password varchar(255),
	createdate timestamp,	
	primary key (id)
	) charset=utf8;

create table adminsession (
	id int NOT NULL auto_increment,
	userid int,
	sessionkey varchar(255),
	sessionstart timestamp,
	sessiontime int, 
	primary key (id)
	) charset=utf8;
	


insert into type (type) values ('Приложение к журналу'),('Сборник программ'),('Демонстрационный диск'),('Прочее');

insert into lable (lable) values ('Прочее');
insert into imgs (type,title,lable,year,number,description,createdate,autorun) values (1,'Диск с грами',5,2008,3,'Самые лучшие гры','2010-02-27 12:00:00','NULL');
