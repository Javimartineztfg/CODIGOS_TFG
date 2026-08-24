function [Angulo_BackTra]=calculoBackTra(azimut,elevacion, P, w,Betha_a,Angulo_seguimiento)
% Definimos un umbral de seguridad, ya que sino está variando constantemente valor de BackTra 

ec_sombra = @(x) P - w*cosd(x) - (w*sind(abs(x))*abs(cosd(azimut))) / tand(elevacion);
    try
        Angulo_BackTra_puro = fzero(ec_sombra, [0, Angulo_seguimiento]);
        Angulo_BackTra_int = abs(Angulo_BackTra_puro) - 2.0;%para que no toque, le ponemos ese margen
        
    
        if azimut<180
            Angulo_BackTra =-Angulo_BackTra_int;
        else
            Angulo_BackTra = Angulo_BackTra_int;
        end
        %BackTrack=1;
    catch 
        Angulo_BackTra=Betha_a;
        %BackTrack=0;
    end

end
