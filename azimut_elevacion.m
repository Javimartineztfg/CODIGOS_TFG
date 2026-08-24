%Método analítico de Spencer
function [azimut_grad,elevacion_grad] = azimut_elevacion(N, hora_decimal)
 
    % constantes valdecaballeros
    latitud = 39.2435;
    longitud = -5.1913;
    lat_rad = deg2rad(latitud);
    % 1. Inicializamos todo el año en horario de invierno (UTC+1), sirve
    % para ponerlo en horario universal
    huso = ones(size(N)) * 1;

    % 2. Filtramos los días que caen en horario de verano (Entre el día 88
    % y el 297, correspondientes al 30 de marzo y 26 de octubre
    % Usamos un "and" lógico (&) para buscar ese rango
    huso(N >= 89 & N < 299) = 2;

    % 3. Calculamos la hora UTC real restando el huso correspondiente
    hora_utc = hora_decimal - huso;
    % 2. CALCULO SOLAR VECTORIZADO (Sin bucles)
    % MATLAB aplicará estas operaciones a los 2976 registros a la vez
    g = (2 * pi / 365) * (N - 1 + (hora_utc - 12) / 24);
    
    declinacion = 0.006918 - 0.399912*cos(g) + 0.070257*sin(g) ...
                - 0.006758*cos(2*g) + 0.000907*sin(2*g) ...
                - 0.002697*cos(3*g) + 0.00148*sin(3*g);
    
    % Ecuación del Tiempo (EqT)
    eqt = 229.18 * (0.000075 + 0.001868*cos(g) - 0.032077*sin(g) ...
          - 0.014615*cos(2*g) - 0.040849*sin(2*g)); 
    
    % Ángulo horario, tiempo ut y
    % el solar serían lo mismo
    % si la tierra fuese una esfera perfecta y estuviese en la longitud 0
    % valde caballeros
    tiempo_solar = (hora_utc * 60) + eqt + (4 * longitud); % gmt=0 si usamos tiempo solar
    omega = deg2rad((tiempo_solar / 4) - 180);
    
    % Elevación y Azimut
    sin_elevacion = sin(lat_rad)*sin(declinacion) + cos(lat_rad)*cos(declinacion).*cos(omega);
    elevacion_rad = asin(sin_elevacion);
    
    % Cálculo de azimut con manejo de cuadrante
    cos_azimut = (sin(declinacion) - sin(lat_rad).*sin_elevacion) ./ (cos(lat_rad).*cos(elevacion_rad));
    cos_azimut = max(min(cos_azimut, 1), -1);
    azimut_rad = acos(cos_azimut);
    % Ajuste de cuadrante para la tarde
    azimut_rad(omega > 0) = 2*pi - azimut_rad(omega > 0);
    azimut_grad=azimut_rad*180/pi;
    elevacion_grad = elevacion_rad * 180 / pi;
end