function [beneficio_dia, SoC, beneficio_15] = calcular_beneficio_dia_v3(precios_dia, prod_dia, Potencia_tot, Energia_tot, bat_min, eff_cd)
% Inicializamos el vector de beneficios
beneficio_15 = zeros(length(prod_dia), 1);
SoC = zeros(length(prod_dia), 1);

max_salida = Potencia_tot * 0.25 * eff_cd; 

% --- CÁLCULO PREVIO ---
soc_temporal = bat_min;
for i = 1:length(prod_dia)
    if prod_dia(i) > 0
        hueco_ext = (Energia_tot - soc_temporal) / eff_cd;
        if prod_dia(i) < hueco_ext
            soc_temporal = soc_temporal + (prod_dia(i) * eff_cd);
        elseif soc_temporal < Energia_tot
            soc_temporal = Energia_tot;
        end
    end
end

energia_bateria_disponible = soc_temporal - bat_min; 
num_descargas = ceil(energia_bateria_disponible / max_salida);
restante_bateria = energia_bateria_disponible - (max_salida * max(0, num_descargas-1));

% --- ÍNDICES ---
ult_ind_sol = find(prod_dia > 0, 1, 'last'); 
if isempty(ult_ind_sol); primer_ind_noche = 1; else; primer_ind_noche = ult_ind_sol + 1; end
idx_noche = primer_ind_noche:length(prod_dia); 

[~, orden_noche_rel] = sort(precios_dia(idx_noche), 'descend');
orden_noche = idx_noche(orden_noche_rel); 

exp_max = orden_noche(1:max(0, num_descargas-1));
if num_descargas > 0
    exp_min = orden_noche(num_descargas);
else
    exp_min = [];
end
% --- BUCLE PRINCIPAL ---
for i=1:length(prod_dia)
    if i==1; soc_anterior=bat_min; else; soc_anterior=SoC(i-1); end

    if prod_dia(i)>0 
        if i==1
            SoC(i)=bat_min+(prod_dia(i)*eff_cd);
            beneficio_15(i) = 0; % Cargando, no hay venta
        else
            hueco_externo = (Energia_tot - soc_anterior) / eff_cd;
            if prod_dia(i)<hueco_externo
                SoC(i)=soc_anterior+(prod_dia(i)*eff_cd);
                beneficio_15(i) = 0; % Cargando, no hay venta
            elseif soc_anterior==Energia_tot
                SoC(i)=SoC(i-1);
                beneficio_15(i) = prod_dia(i)*precios_dia(i); % Venta total excedente
            else
                SoC(i)=Energia_tot;
                Excedente=prod_dia(i)-hueco_externo;
                beneficio_15(i) = Excedente*precios_dia(i); % Venta parcial
            end
        end
    else
        % ESTADO NOCHE
        if ismember(i,exp_max)
            beneficio_15(i) = (max_salida * eff_cd) * precios_dia(i);
            SoC(i) = soc_anterior - max_salida;

        elseif i==exp_min
            beneficio_15(i) = (restante_bateria * eff_cd) * precios_dia(i);
            SoC(i) = soc_anterior - restante_bateria;
        else
            SoC(i) = soc_anterior;
            beneficio_15(i) = 0;
        end
    end
end

% Calculamos el total al final
beneficio_dia = sum(beneficio_15);
end