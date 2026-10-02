function f = filtros()
    % Retorna la estructura con todos los manejadores de funciones creados
    f.ecualizacionHistograma = @ecualizacionHistograma;
    f.filtrosEstadisticos    = @filtrosEstadisticos;
    f.combinacion            = @aplicarCombinacion;
    f.primeraderivadaAtras   = @primeraDerivadaAtras;
    f.primeraderivadaAdelante= @primeraDerivadaAdelante;
    f.segundaderivada        = @segundaDerivada;
    f.laplaciono4            = @laplaciano4;
    f.laplaciono8            = @laplaciano8;
    f.laplaciano8A           = @laplaciano8A;
    f.highboost              = @highBoost;
    f.mediana                = @filtrarMediana;
    f.gaussiano              = @filtrarGaussiano;
    f.caja                   = @filtrarCaja;
    f.promedio_pesado        = @filtrarPromedioPesado;
    f.clahe                  = @aplicarCLAHE;
end

% =========================================================================
% 1. MEJORAMIENTO POR HISTOGRAMA
% =========================================================================
function R = ecualizacionHistograma(I)
    imagen_lab = rgb2lab(I);
    L = imagen_lab(:,:,1) / 100; % Normalizar L a [0,1]
    
    [nk, ~] = imhist(L, 256);
    cdf = cumsum(nk) / sum(nk);
    
    % Convertir L de forma segura a uint8 para indexación en CDF
    L_uint8 = im2uint8(L);
    L_eq = cdf(double(L_uint8) + 1);
    
    imagen_lab(:,:,1) = L_eq * 100;
    R = lab2rgb(imagen_lab);
end

function img_salida = aplicarCLAHE(img, clip_limit, num_tiles)
    if nargin < 2, clip_limit = 0.02; end
    if nargin < 3, num_tiles = [8 8]; end
    
    img_lab = rgb2lab(img);
    L_norm = mat2gray(img_lab(:,:,1));
    L_clahe = adapthisteq(L_norm, 'ClipLimit', clip_limit, 'NumTiles', num_tiles);
    img_lab(:,:,1) = L_clahe * 100;
    img_salida = lab2rgb(img_lab);
end

% =========================================================================
% 2. FILTROS SUAVIZANTES (LINEALES Y DE ORDEN ESTADÍSTICO)
% =========================================================================
function img_salida = filtrarMediana(img, tam_ventana)
    if nargin < 2, tam_ventana = [3 3]; end
    med_R = medfilt2(img(:,:,1), tam_ventana);
    med_G = medfilt2(img(:,:,2), tam_ventana);
    med_B = medfilt2(img(:,:,3), tam_ventana);
    img_salida = cat(3, med_R, med_G, med_B);
end

function img_salida = filtrarGaussiano(img, sigma)
    if nargin < 2, sigma = 1.0; end
    img_salida = imgaussfilt(img, sigma);
end

function img_salida = filtrarCaja(img)
    w = ones(3,3) / 9;
    img_salida = imfilter(img, w, 'replicate');
end

function img_salida = filtrarPromedioPesado(img)
    w = [1 2 1; 2 4 2; 1 2 1] / 16;
    img_salida = imfilter(img, w, 'replicate');
end

% =========================================================================
% 3. FILTROS REALZANTES (DERIVADAS Y HIGHBOOST)
% =========================================================================
function img_salida = primeraDerivadaAtras(img)
    img = im2double(img);
    mascara = [-1 1];
    derivada = imfilter(img, mascara, 'replicate');
    img_salida = max(0, min(1, img + derivada));
end

function img_salida = primeraDerivadaAdelante(img)
    img = im2double(img);
    mascara = [1 -1];
    derivada = imfilter(img, mascara, 'replicate');
    img_salida = max(0, min(1, img + derivada));
end

function img_salida = segundaDerivada(img)
    img = im2double(img);
    mascara = [1 -2 1];
    derivada = imfilter(img, mascara, 'replicate');
    img_salida = max(0, min(1, img - derivada));
end

function img_salida = laplaciano4(img)
    img = im2double(img);
    mascara = [0  1  0;
               1 -4  1;
               0  1  0];
    lap = imfilter(img, mascara, 'replicate');
    img_salida = max(0, min(1, img - lap));
end

function img_salida = laplaciano8(img)
    img = im2double(img);
    mascara = [1  1  1;
               1 -8  1;
               1  1  1];
    lap = imfilter(img, mascara, 'replicate');
    img_salida = max(0, min(1, img - lap));
end

function img_salida = laplaciano8A(img)
    img = im2double(img);
    mascara = [-1 -1 -1;
               -1  8 -1;
               -1 -1 -1];
    lap = imfilter(img, mascara, 'replicate');
    img_salida = max(0, min(1, img + lap));
end

% --- HIGHBOOST CORRECTO Y BALANCEADO ---
function img_salida = highBoost(img, radio, k)
    if nargin < 2, radio = 1.5; end
    if nargin < 3, k = 1.0; end % Factor de realce (k >= 0)
    
    img = im2double(img);
    
    % 1. Máscara de desenfoque (suavizado gaussiano)
    img_suave = imgaussfilt(img, radio);
    
    % 2. Máscara de altas frecuencias (detalles)
    mascara_detalles = img - img_suave;
    
    % 3. Amplificación e integración
    img_salida = img + k * mascara_detalles;
    
    % 4. Normalización al rango estándar [0, 1]
    img_salida = max(0, min(1, img_salida));
end

% =========================================================================
% 4. COMBINACIÓN DE FILTROS
% =========================================================================
function img_salida = aplicarCombinacion(img)
    img_temp = filtrarMediana(img, [3 3]);
    img_temp = aplicarCLAHE(img_temp, 0.02, [8 8]);
    img_temp = filtrarGaussiano(img_temp, 1.0);
    img_salida = highBoost(img_temp, 1.5, 0.8);
end

% =========================================================================
% 5. EVALUACIÓN CON MODELOS DE RUIDO Y FILTROS ESTADÍSTICOS
% =========================================================================
function [gaussiano, uniforme, sal, pimienta] = filtrosEstadisticos(I)
    I = im2double(I);
    [M, N, C] = size(I);
    
    gaussiano = zeros(M, N, C);
    uniforme  = zeros(M, N, C);
    sal       = zeros(M, N, C);
    pimienta  = zeros(M, N, C);

    w_prom = ones(5, 5) / 25;

    for canal = 1:C
        % 1. Ruido Gaussiano -> Filtro Promedio 5x5
        ImgG = imnoise(I(:,:,canal), 'gaussian', 0, 0.01);
        gaussiano(:,:,canal) = imfilter(ImgG, w_prom, 'replicate');

        % 2. Ruido Uniforme -> Filtro Promedio 5x5
        ruido = (rand(M, N) - 0.5) * 0.2;
        ImgU = max(0, min(1, I(:,:,canal) + ruido));
        uniforme(:,:,canal) = imfilter(ImgU, w_prom, 'replicate');

        % 3. Ruido de Sal (Blanco) -> Filtro Mínimo 5x5
        ImgSal = I(:,:,canal);
        mascaraSal = rand(M, N) < 0.02;
        ImgSal(mascaraSal) = 1;
        sal(:,:,canal) = ordfilt2(ImgSal, 1, ones(5,5));

        % 4. Ruido de Pimienta (Negro) -> Filtro Máximo 5x5
        ImgPimienta = I(:,:,canal);
        mascaraPimienta = rand(M, N) < 0.02;
        ImgPimienta(mascaraPimienta) = 0;
        pimienta(:,:,canal) = ordfilt2(ImgPimienta, 25, ones(5,5));
    end

    gaussiano = im2uint8(gaussiano);
    uniforme  = im2uint8(uniforme);
    sal       = im2uint8(sal);
    pimienta  = im2uint8(pimienta);
end