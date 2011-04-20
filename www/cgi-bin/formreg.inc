<form action="registration.pl" method="post">
	<table cellspacing=0 align="center" border=1 class="maintable">
	<tr><td>Имя пользователя:</td><td><input type="text" name="username"></td></tr>
	<tr><td>Пароль:<br><span class="remarks">Не менее шести символов</span></td><td><input type="password" name="password"></td></tr>
	<tr><td>Повторите пароль:</td><td><input type="password" name="repassword"></td></tr>
	<tr><td><input type="submit" value="Создать"></td><td><input type="reset" value="Сброс"></td></tr>
	</table>
	<input type="hidden" name="act" value="create">
	</form>


