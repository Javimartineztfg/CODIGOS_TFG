clc;
%clear all;

%%
% Creamos el cliente apuntando a tu PLC local sin seguridad
uaClient = opcua("localhost", 4840, MessageSecurityMode="None", ChannelSecurityPolicy="None");

% Conectamos directamente de forma anónima
connect(uaClient);
ruta_archivo='C:\Users\marti\OneDrive\Desktop\ETSI\TFG\RADIACIÓN\RADIACIÓN\Rad Vald 2\202512 Datos EM Valdecaballeros II.xlsm';
ruta_omie = 'C:\Users\marti\OneDrive\Documentos\MATLAB\PRECIOS OMIE EXCEL POR MES\12. Precio OMIE Diciembre.xlsx';
dia_inicio=1;
dia_fin=31; %este día también incluido
[N, hora_decimal, dia, mes, ano, hora, minuto, radiacion] = cargar_datos_solares(ruta_archivo, dia_inicio, dia_fin);
[azimut_grad,elevacion_grad] = azimut_elevacion(N, hora_decimal);

data = readtable(ruta_omie,'Range', 'A1:B9000');
precio_15=table2array(data(:,2))/1000;

P= 25; %DISTANCIA ENTRE EJES DE SEGUIDOR
w= 11.868;%ancho del panel
PR_mes=[0.96,0.95,0.94,0.86,0.8,0.79,0.89,0.84,0.87,0.89,0.86,0.95];
Potencia_pico = 5160; %KW
At=15/60; %Nos dará la energía en kWh
PR=PR_mes(12);%Performance ratio, media entre todos los meses

%escribimos la variable minutos reales desde el inicio
medida=15;
nodoMinutosreales = findNodeByName(uaClient.Namespace, 'minutos_reales', '-once');
writeValue(uaClient, nodoMinutosreales, medida);

%Incializamos estas variables 
Distancia_extremos=0;
L_p=0;
Betha=0;
BackTrack=0;
Angulo_BackTra=0;

%%

%empezamos el bucle en 2 para que no se sature a la hora de calcular
%posiciones medias en la primera vuelta (ano(0))
Energia_exp_15=zeros(length(radiacion)-1,1);
Beneficio_15 = zeros(length(radiacion)-1,1);
for i=2:length(hora)
   
%nodos escritura
nodoHora = findNodeByName(uaClient.Namespace, 'hora', '-once');
nodoMinuto = findNodeByName(uaClient.Namespace, 'minuto', '-once');
nodoDia = findNodeByName(uaClient.Namespace, 'dia', '-once');
nodoMes = findNodeByName(uaClient.Namespace, 'mes', '-once');
nodoAno = findNodeByName(uaClient.Namespace, 'ano', '-once');
nodoAzimut = findNodeByName(uaClient.Namespace, 'azimut_grad', '-once');
nodoElevacion = findNodeByName(uaClient.Namespace, 'elevacion_grad', '-once');
nodoRadiacion = findNodeByName(uaClient.Namespace, 'radiacion', '-once');
nodoDistancia = findNodeByName(uaClient.Namespace, 'Distancia_extremos', '-once');
nodoLp = findNodeByName(uaClient.Namespace, 'L_p', '-once');
nodoBackTra = findNodeByName(uaClient.Namespace, 'BackTra', '-once');
nodoAnguloBT = findNodeByName(uaClient.Namespace, 'Angulo_BackTra', '-once');

%nodos lectura
nodoBetha = findNodeByName(uaClient.Namespace, 'Angulo_real_seg', '-once');
nodoAngulosol= findNodeByName(uaClient.Namespace, 'Angulo_sol', '-once');
nodoAnguloSeguimiento = findNodeByName(uaClient.Namespace, 'Angulo_seguimiento', '-once');

%escritura en variables de Codesys
writeValue(uaClient, nodoHora, hora(i));
writeValue(uaClient, nodoMinuto, minuto(i));
writeValue(uaClient, nodoDia, dia(i));
writeValue(uaClient, nodoMes, mes(i));
writeValue(uaClient, nodoAno, ano(i));
writeValue(uaClient, nodoAzimut, azimut_grad(i));
writeValue(uaClient, nodoElevacion, elevacion_grad(i));
writeValue(uaClient, nodoRadiacion, radiacion(i));
writeValue(uaClient, nodoBackTra,BackTrack);
writeValue(uaClient,nodoAnguloBT ,Angulo_BackTra);

%lectura variable codesys
Betha_a=readValue(uaClient, nodoBetha);
Angulo_sol_a=readValue(uaClient, nodoAngulosol);
Angulo_seguimiento=readValue(uaClient, nodoAnguloSeguimiento);

%FUNCIÓN BACKTRACKING PARA SABER EL ÁNGULO Y CUÁNDO HAY QUE APLICARLO
[Angulo_BackTra]=calculoBackTra(azimut_grad(i),elevacion_grad(i), P, w,Betha_a,Angulo_seguimiento);

%PAUSE
pause(0.05)
Betha = readValue(uaClient, nodoBetha);
Angulo_sol=readValue(uaClient, nodoAngulosol);

%Cálculo de la energía export
Energia_exp_15(i-1)=Calculo_energia(Potencia_pico,Betha_a,Betha,i,azimut_grad,elevacion_grad,radiacion,At,Angulo_sol,Angulo_sol_a,PR);
%fprintf('la energía exportada:%f  betha:%f \n radiacion_med: %f \n',Energia_exp_15(i), Betha,radiacion);
%fprintf('betha : %f \n Energía exportada: %f \n',Betha,Energia_exp(i));
Beneficio_15(i-1)=beneficio(Energia_exp_15(i-1),precio_15(i-1));
end
%%

%Lo convertimos en horario la energía exportada
[Energia_hor_15] = convertidor_horario(15,Energia_exp_15);
%fprintf('La Energía total es %f',sum(Energia_exp_15));




%PARA EXPORTAR DATOS A EXCEL
%T = table(Energia_hor_15(:),'VariableNames', {'Energia_Horaria_Modelo15'});
% % 3. Exportamos al Excel en una sola hoja
%filename = 'Energia exportada Enero v2.xlsx';
%writetable(T, filename, 'Sheet', 'Datos_Combinados');
%%