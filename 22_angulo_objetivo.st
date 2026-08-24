IF ESTADO =4 THEN
	Angulo_obj:=0;
ELSIF ESTADO=3 THEN
	Angulo_obj:= 0;
ELSIF ESTADO =2 THEN
	Angulo_obj:=Angulo_BackTra;
ELSE
	Angulo_obj:=Angulo_seguimiento;
END_IF