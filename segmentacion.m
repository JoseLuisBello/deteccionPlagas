function s = segmentacion()
    % Retorna la estructura con los métodos de segmentación
    s.canny            = @segmentarCanny;
    s.umbralGlobal     = @segmentarUmbralGlobal;
    s.otsu             = @segmentarOtsu;
    s.kmeans           = @segmentarKMeans;
end

% =========================================================================
% 1. DETECTOR DE BORDES DE CANNY
% =========================================================================
function [bordes, img_segmentada] = segmentarCanny(img, umbrales, sigma)
    % Recibe imagen RGB o escala de grises
    if nargin < 2 || isempty(umbrales), umbrales = []; end % Automático si está vacío
    if nargin < 3, sigma = 1.0; end
    
    if size(img, 3) == 3
        img_gris = rgb2gray(img);
    else
        img_gris = img;
    end
    
    % Detección de bordes con Canny
    if isempty(umbrales)
        bordes = edge(img_gris, 'Canny', [], sigma);
    else
        bordes = edge(img_gris, 'Canny', umbrales, sigma);
    end
    
    % Máscara aplicada a la imagen original
    img_segmentada = img;
    if size(img, 3) == 3
        for c = 1:3
            canal = img_segmentada(:,:,c);
            canal(~bordes) = 0;
            img_segmentada(:,:,c) = canal;
        end
    else
        img_segmentada(~bordes) = 0;
    end
end

% =========================================================================
% 2. UMBRALIZACIÓN GLOBAL (UMBRAL FIJO)
% =========================================================================
function [mascara, img_segmentada] = segmentarUmbralGlobal(img, umbral)
    % umbral: valor entre 0 y 1 (o 0 a 255)
    if nargin < 2, umbral = 0.5; end
    
    if size(img, 3) == 3
        img_gris = rgb2gray(img);
    else
        img_gris = img;
    end
    
    img_double = im2double(img_gris);
    
    % Generación de la máscara binaria
    mascara = img_double > umbral;
    
    % Aplicación de la máscara sobre la imagen original
    img_segmentada = aplicarMascara(img, mascara);
end

% =========================================================================
% 3. UMBRALIZACIÓN DE OTSU (UN UMBRAL AUTOMÁTICO)
% =========================================================================
function [mascara, img_segmentada, umbral_calculado] = segmentarOtsu(img)
    if size(img, 3) == 3
        img_gris = rgb2gray(img);
    else
        img_gris = img;
    end
    
    % Cálculo del umbral óptimo mediante Otsu
    umbral_calculado = graythresh(img_gris);
    
    % Máscara binaria
    mascara = imbinarize(img_gris, umbral_calculado);
    
    % Segmentación sobre la imagen original
    img_segmentada = aplicarMascara(img, mascara);
end

% =========================================================================
% 4. K-MEANS EN ESPACIO DE COLOR L*a*b* (COMPATIBLE)
% =========================================================================
function [etiquetas, img_segmentada, mascara_hoja] = segmentarKMeans(img, K)
    if nargin < 2, K = 3; end 
    
    if size(img, 3) == 1
        img = cat(3, img, img, img);
    end
    
    % Conversión a espacio L*a*b*
    img_lab = rgb2lab(img);
    ab = img_lab(:,:,2:3);
    
    [M, N, ~] = size(ab);
    datos_ab = reshape(ab, M*N, 2);
    
    % Normalizar canales a/b a rango [0, 1] para rápida convergencia
    datos_ab = mat2gray(datos_ab);
    
    % Agrupamiento K-Means compatible con todas las versiones de MATLAB
    opts = statset('Display', 'off', 'MaxIter', 300);
    [idx, ~] = kmeans(datos_ab, K, 'Start', 'sample', ...
                      'Replicates', 2, 'Options', opts);
                  
    etiquetas = reshape(idx, M, N);
    
    % Identificar el clúster con mayor presencia de verde (menor valor en canal 'a')
    a_canal = img_lab(:,:,2);
    promedios_a = zeros(K, 1);
    for k = 1:K
        promedios_a(k) = mean(a_canal(etiquetas == k));
    end
    
    [~, cluster_hoja] = min(promedios_a);
    mascara_hoja = (etiquetas == cluster_hoja);
    
    % Aplicar la máscara a la imagen
    img_segmentada = aplicarMascara(img, mascara_hoja);
end

% =========================================================================
% FUNCIÓN AUXILIAR PARA APLICAR MÁSCARA BINARIA EN RGB O GRISES
% =========================================================================
function img_salida = aplicarMascara(img, mascara)
    img_salida = img;
    if size(img, 3) == 3
        for c = 1:3
            canal = img_salida(:,:,c);
            canal(~mascara) = 0;
            img_salida(:,:,c) = canal;
        end
    else
        img_salida(~mascara) = 0;
    end
end