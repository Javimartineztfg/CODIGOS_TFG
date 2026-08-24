clc;
clear all;
%%
% Creamos el cliente apuntando a tu PLC local sin seguridad
uaClient = opcua("localhost", 4840, MessageSecurityMode="None", ChannelSecurityPolicy="None");

% Conectamos directamente de forma anónima
connect(uaClient);

%que datos queremos sacar? de que días 
dia_inicio=15;
dia_fin=15;
ruta_archivo= 'C:\Users\marti\OneDrive\Desktop\ETSI\TFG\RADIACIÓN\RADIACIÓN\Rad Vald 2\202512 Datos EM Valdecaballeros II.xlsm';%202512 ValdecaballerosDatos EM.xlsx
[N, hora_decimal, dia, mes, ano, hora, minuto, radiacion] = cargar_datos_solares(ruta_archivo, dia_inicio, dia_fin);
[azimut_grad,elevacion_grad] = azimut_elevacion(N, hora_decimal);

%para la simulación
tiempo_original = 1:1:length(ano);
tiempo_minuto = 1:(1/15):length(ano);

Potencia_pico = 5160; %KW
At=1/60; %Nos dará la energía en kWh
PR=0.86;

P= 25; %DISTANCIA ENTRE EJES DE SEGUIDOR
w= 11.868;%ancho del panel


% MATLAB interpola el Sol mágicamente minuto a minuto
ano = interp1(tiempo_original, ano, tiempo_minuto, 'previous');
hora = interp1(tiempo_original, hora, tiempo_minuto, 'previous');
mes = interp1(tiempo_original, mes, tiempo_minuto, 'previous');
dia = interp1(tiempo_original, dia, tiempo_minuto, 'previous');
minuto = interp1(tiempo_original, minuto, tiempo_minuto, 'linear');
elevacion_grad = interp1(tiempo_original, elevacion_grad, tiempo_minuto, 'linear');
azimut_grad = interp1(tiempo_original, azimut_grad, tiempo_minuto, 'linear');
radiacion = interp1(tiempo_original, radiacion, tiempo_minuto, 'linear');

%Escribimos variable de minutos reales
medida=1;
nodoMinutosreales = findNodeByName(uaClient.Namespace, 'minutos_reales', '-once');
writeValue(uaClient, nodoMinutosreales, medida);

%%
% empezamos el bucle en 2 para que no se sature a la hora de calcular%
%posiciones medias en la primera vuelta (ano(0))

Energia_exp_1=zeros(length(radiacion),1);

%Incializamos estas variables 
Distancia_extremos=0;
L_p=0;
Betha=0;
BackTrack=0;
Angulo_BackTra=0;
Betha_a=0;
beta_ev = zeros(length(radiacion),1);
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

    %FUNCIÓN BACKTRACKING PARA SABER EL ÁNGULO 
    [Angulo_BackTra]=calculoBackTra(azimut_grad(i),elevacion_grad(i), P, w,Betha_a,Angulo_seguimiento);
    
    pause(0.05)
    Betha = readValue(uaClient, nodoBetha);
    Angulo_sol=readValue(uaClient, nodoAngulosol);

    %Cálculo de la energía export
    Energia_exp_15(i-1)=Calculo_energia(Potencia_pico,Betha_a,Betha,i,azimut_grad,elevacion_grad,radiacion,At,Angulo_sol,Angulo_sol_a,PR);
    beta_ev(i-1)=Evolucion_beta(Betha_a,Betha,i,Angulo_sol,Angulo_sol_a);
    % fprintf('la energía exportada:%f  betha:%f \n radiacion_med: %f \n',Energia_exp(i), Betha,radiacion);
    %fprintf('betha : %f \n Energía exportada: %f \n',Betha,Energia_exp(i));

end
%%

%ruta_produ= 'C:\Users\marti\OneDrive\Desktop\ETSI\TFG\PRODUCCIÓN\PRODUCCIÓN\2025_VALDE2\202512 Curva de carga Valdecaballeros II.xlsx';
%[Energia_exp_real] = cargar_produccion_excel(ruta_produ, dia_inicio, dia_fin);

