//CONDICIONES ESTADO
Permiso_seg:=FALSE;
IF Viento >=Vel_max THEN
ESTADO:=4;
ESTADO_VISUAL:=’VIENTO->POS DEFENSA’;
ELSIF Angulo_sol>180 THEN
ESTADO:=3;
ESTADO_VISUAL:=’NOCHE’;
Angulo_seguimiento:=0;
ELSIF BackTra = 1 THEN
ESTADO:=2;
Angulo_obj:=Angulo_BackTra;
ESTADO_VISUAL:=’BACKTRACKING’;
ELSIF Error_seg >3 THEN
ESTADO:=1;
Angulo_seguimiento:=Angulo_sol-90;
Angulo_obj:=Angulo_seguimiento;
ESTADO_VISUAL:=’SEGUIMIENTO’;
Permiso_seg:=TRUE;
ELSE
ESTADO:=0;
ESTADO_VISUAL:=’REPOSO DE SEGUIMIENTO’;
END_IF