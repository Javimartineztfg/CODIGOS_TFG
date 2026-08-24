Angulo_real_seg_rad:=Angulo_real_seg*pi/180;
Angulo_seguimiento_rad:=Angulo_seguimiento*pi/180;
//SIMULACIÓN DE LA SOMBRA
L_p:=(w*SIN(ABS(Angulo_real_seg_rad))*ABS(COS(azimut_rad))) / MAX(TAN(elevacion_rad),0.001);
L_p_teorico:=(w*SIN(ABS(Angulo_seguimiento_rad))*ABS(COS(azimut_rad))) / MAX(TAN(elevacion_rad),0.001);
Distancia_extremos:=P-w*COS(Angulo_real_seg_rad);

//ACTIVAR VARIABLE BACKTRACKING
IF L_p_teorico>=umbral_entrada*Distancia_extremos THEN
	BackTra:=1;
ELSIF L_p_teorico<=umbral_salida*Distancia_extremos THEN
	BackTra:=0;
END_IF