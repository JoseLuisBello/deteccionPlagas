%% PROCESAMIENTO DE IMAGEN DE PLANTA
% Filtros:
% 1. Estadístico: Mediana
% 2. Suavizante: Gaussiano
% 3. Ecualización: CLAHE
% 4. Realzante: Unsharp Mask

clc;
clear;
close all;

%% 1. SELECCIONAR IMAGEN

[archivo, ruta] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png;*.bmp', 'Archivos de imagen'}, ...
    'Selecciona una imagen de una planta');

% Verificar si el usuario canceló
if isequal(archivo, 0)
    disp('No se seleccionó ninguna imagen.');
    return;
end

% Leer imagen
imagen = imread(fullfile(ruta, archivo));

%% 2. MOSTRAR INFORMACION DE LA IMAGEN

disp('-----------------------------------------');
disp('INFORMACION DE LA IMAGEN');
disp('-----------------------------------------');

fprintf('Nombre: %s\n', archivo);
fprintf('Dimensiones: %d x %d\n', size(imagen,1), size(imagen,2));

if size(imagen,3) == 3
    disp('Tipo de imagen: RGB');
else
    disp('Tipo de imagen: Escala de grises');
end

%% 3. CONVERTIR A RGB SI ES NECESARIO

if size(imagen,3) == 1
    imagen = cat(3, imagen, imagen, imagen);
end

%% 4. FILTRO ESTADISTICO: MEDIANA

% Aplicamos el filtro de mediana a cada canal RGB
mediana_R = medfilt2(imagen(:,:,1), [5 5]);
mediana_G = medfilt2(imagen(:,:,2), [5 5]);
mediana_B = medfilt2(imagen(:,:,3), [5 5]);

imagen_mediana = cat(3, mediana_R, mediana_G, mediana_B);

%% 5. FILTRO SUAVIZANTE: GAUSSIANO

% Sigma = 2
imagen_gaussiana = imgaussfilt(imagen, 2);

%% 6. ECUALIZACION: CLAHE

% Convertimos RGB a LAB
imagen_lab = rgb2lab(imagen);

% Extraemos el canal L (luminosidad)
L = imagen_lab(:,:,1);

% Normalizamos L al rango [0,1]
L_normalizado = mat2gray(L);

% Aplicamos CLAHE
L_clahe = adapthisteq(L_normalizado, ...
    'ClipLimit', 0.02, ...
    'NumTiles', [8 8]);

% Regresamos al rango original del canal L
L_clahe = L_clahe * 100;

% Reemplazamos el canal L
imagen_lab(:,:,1) = L_clahe;

% Convertimos nuevamente a RGB
imagen_clahe = lab2rgb(imagen_lab);

%% 7. FILTRO REALZANTE: UNSHARP MASK

imagen_realzada = imsharpen(imagen, ...
    'Radius', 2, ...
    'Amount', 1.5);

%% 8. COMBINACION DE FILTROS

% Primero reducimos ruido con mediana
combinacion = imagen_mediana;

% Después mejoramos el contraste con CLAHE
combinacion_lab = rgb2lab(combinacion);

L = combinacion_lab(:,:,1);
L_normalizado = mat2gray(L);

L_clahe = adapthisteq(L_normalizado, ...
    'ClipLimit', 0.02, ...
    'NumTiles', [8 8]);

L_clahe = L_clahe * 100;

combinacion_lab(:,:,1) = L_clahe;

combinacion = lab2rgb(combinacion_lab);

% Finalmente realzamos los detalles
combinacion = imsharpen(combinacion, ...
    'Radius', 2, ...
    'Amount', 1.5);

%% 9. MOSTRAR RESULTADOS

figure('Name','Comparacion de filtros');

subplot(2,3,1);
imshow(imagen);
title('Imagen original');

subplot(2,3,2);
imshow(imagen_mediana);
title('Filtro de mediana');

subplot(2,3,3);
imshow(imagen_gaussiana);
title('Filtro gaussiano');

subplot(2,3,4);
imshow(imagen_clahe);
title('CLAHE');

subplot(2,3,5);
imshow(imagen_realzada);
title('Unsharp Mask');

subplot(2,3,6);
imshow(combinacion);
title('Combinacion');

%% 10. MOSTRAR HISTOGRAMAS

figure('Name','Histogramas');

subplot(2,1,1);
imhist(rgb2gray(imagen));
title('Histograma - Imagen original');

subplot(2,1,2);
imhist(rgb2gray(imagen_clahe));
title('Histograma - Imagen con CLAHE');

%% 11. GUARDAR RESULTADOS

imwrite(imagen_mediana, 'resultado_mediana.png');
imwrite(imagen_gaussiana, 'resultado_gaussiano.png');
imwrite(imagen_clahe, 'resultado_clahe.png');
imwrite(imagen_realzada, 'resultado_unsharp.png');
imwrite(combinacion, 'resultado_combinacion.png');

disp('-----------------------------------------');
disp('PROCESAMIENTO TERMINADO');
disp('-----------------------------------------');

disp('Se guardaron los siguientes archivos:');
disp('resultado_mediana.png');
disp('resultado_gaussiano.png');
disp('resultado_clahe.png');
disp('resultado_unsharp.png');
disp('resultado_combinacion.png');