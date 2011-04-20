create table imgtypes (
	id int NOT NULL auto_increment,
	type varchar(64),
	primary key (id)
	);

insert into imgtypes (type) values
	('Приложение к журналу'),
	('Демонстрационный диск'),
	('Прочее'),
	('');

create table adminuser (
	id smallint NOT NULL auto_increment,
	username varchar(32),
	password varchar(127),
	description varchar(255),
	primary key (id)
	);

create table users (
	id int NOT NULL auto_increment,
	username varchar(16),
	password varchar(255),
	email varchar(255),
	dept varchar(255),
	name varchar(255),
	sharepath varchar(32),
	lastimgid int,
	dateofreg date,
	banned tinyint(1) DEFAULT NULL,
	lastvisit datetime,
	primary key (id)
	);

create table imgs (
	id int NOT NULL auto_increment,
	imgname varchar(255),
	imgtype int,
	descid int,
	orderdate datetime,
	imgpath varchar(255),
	primary key (id),
	foreign key (imgtype) references imgtypes(id)
	    ON UPDATE CASCADE
	    ON DELETE RESTRICT,
	foreign key (descid) references description(id)   
	    ON UPDATE CASCADE
	    ON DELETE RESTRICT
	);

create table description(
	id int NOT NULL auto_increment,
	descript text,
	magazine varchar(255) default NULL,
	magyear year default NULL,
	magnumber smallint default NULL,
	primary key (id)
	);
    </div>
    <div class="menu"><span class="menu"><a href="http://localhost/index.shtml">Главная</a></span><span class="menu"><a href="http://localhost/admin/index.shtml">Администрирование</a></span><span class="menu"><a href="http://localhost/catalog.shtml">Каталог дисков</a></span><span class="menu"><a href="http://localhost/enter.shtml">Вход в систему</a></span></div>
    <div class="adminmenu" width=100px>
    <div class="adminmenuitem"><a href="http://localhost/">Добавить новый образ</a> </div><div class="adminmenuitem"><a href="http://localhost/">Редактировать каталог дисков</a> </div><div class="adminmenuitem"><a href="http://localhost/">Список пользователей системы</a> </div><div class="adminmenuitem"><a href="http://localhost/">Активные сессии</a> </div><div class="adminmenuitem"><a href="http://localhost/cgi-bin/adminuser.pl?act=add">Список Суперпользователей</a> </div>

    </div>
    <div class="tabledata">Lores ipsum</div>


create table sessions(
	id int NOT NULL auto_increment,
	userid int,
	imageid int,
	sessionbegin datetime,
	sessionkey varchar(255),
	primary key (id),
	foreign key (userid) references users(id)
	    ON UPDATE CASCADE
	    ON DELETE RESTRICT,
	foreign key (imageid) references imgs(id)
	    ON UPDATE CASCADE
	    ON DELETE RESTRICT
	);
create table adminsession(
	id int NOT NULL auto_increment,
	userid int,
	sessionstart datetime,
	sessionkey varchar(255),
	foreign key (userid) references adminuser(id),
	primary key (id)
	);
	


create view magfull as
    select imgs.imgname,description,descript,description.magazine,description.magyear,description.magnumber 
    from imgs,description where imgs.imgtype=1 and imgs.descid=description.id;

create view magshort as
    select imgs.imgname, description.magazine,description.magyear,description,magnumber
    from img,description where imgs.imgtype=1 and imgs.descid=description.id;

create view fullview as
    select imgtype.type,img.imgname,description.magazine,description.magyear,description.magnumber
    from imgs,imgtype,description where img.descid=description.id and imgtype.id=imgs.imgtype;

create view userlist as
    select users.usename,users.name,users.email,users.dept,users.dateofregб,users.lastvisit
    from users

create view activesessions as
    select users.username,img.imgname,sessions.sessionbegin
    from imgs,sessions,users where sessions.imageid=imgs.id and sessions.userid=users.id;

create view alladmins as
    select id,username,description from adminuser;	    

discbase windowssuxx




