clc; clear all; close all;

% --- 1. CARGA DE DATOS ---
ruta_archivo='C:\Users\marti\OneDrive\Desktop\ETSI\TFG\PRODUCCIÓN_OMIE AÑO ENTERO\EXCEL_COMPLETO_AÑO.xlsx';
data = readtable(ruta_archivo,'Range','A2:C40000');
energia_producida_groso = table2array(data(:,2))/1000;
precio_omie_groso = table2array(data(:,3));
rango_util=28:34971; 
energia_producida=energia_producida_groso(rango_util);
precios_omie=precio_omie_groso(rango_util);

% --- 2. PARÁMETROS FIJOS (Tu Escenario) ---
potencia_tot_vec = 0:0.2:23.2; 
horas_vec = 0:0.5:6;
ef_round_trip = 0.92;
eff_one_way = sqrt(ef_round_trip); 
porcentaje_bat_min = 0.1;

% Variables fijas solicitadas
r = 0.05;               % Tasa de descuento 5%     
coste_kWh = 230000;     % 230k €/MWh -> €/MWh
n = 15;                 % Vida útil

% --- 3. CÁLCULO FÍSICO ---
prod_matriz = reshape(energia_producida, 96, 364);
precios_matriz = reshape(precios_omie, 96, 364);
ingreso_base_anual = sum(energia_producida .* precios_omie);

matriz_beneficio_total = zeros(length(potencia_tot_vec), length(horas_vec));

disp('Calculando simulación física...');
for i_p = 1:length(potencia_tot_vec)
    for i_h = 1:length(horas_vec)
        Potencia_tot = potencia_tot_vec(i_p);
        Energia_tot = Potencia_tot * horas_vec(i_h);
        beneficio_anual = 0;
        for dia=1:364
            [beneficio_dia, ~] = calcular_beneficio_dia_v2(precios_matriz(:, dia), prod_matriz(:, dia), Potencia_tot, Energia_tot, porcentaje_bat_min*Energia_tot, eff_one_way);
            beneficio_anual = beneficio_anual + beneficio_dia;
        end
        matriz_beneficio_total(i_p, i_h) = beneficio_anual;
    end
end

% --- 4. CÁLCULO FINANCIERO (VAN) ---
[H_mesh, P_mesh] = meshgrid(horas_vec, potencia_tot_vec);
Energia_mesh = P_mesh .* H_mesh; 
factor = (1 - (1 + r)^-n) / r;

% Matriz CAPEX constante
matriz_capex = coste_kWh * Energia_mesh;
matriz_VAN = ((matriz_beneficio_total - ingreso_base_anual) * factor) - matriz_capex;

