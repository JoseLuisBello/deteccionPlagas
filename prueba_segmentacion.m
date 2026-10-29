% =========================================================================
% SCRIPT DE PRUEBA: EVALUACIÓN DE MÉTODOS DE SEGMENTACIÓN (SEGUNDO PARCIAL)
% =========================================================================
clc; clear; close all;

% 1. SELECCIONAR IMAGEN DE HOJA
[archivo, ruta] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png;*.bmp', 'Archivos de imagen (*.jpg, *.png, *.bmp)'}, ...
    'Selecciona una imagen del New Plant Diseases Dataset');
if isequal(archivo, 0)
    disp('Selección cancelada.');
    return;
end

imgOriginal = imread(fullfile(ruta, archivo));
if size(imgOriginal, 3) == 1
    imgOriginal = cat(3, imgOriginal, imgOriginal, imgOriginal);
end

% 2. CARGAR MÓDULOS DE FILTROS Y SEGMENTACIÓN
f = filtros();
s = segmentacion();

% 3. PREPROCESAMIENTO (Pipeline Combinación 1: Mediana + CLAHE)
img_suave = f.mediana(imgOriginal, [3 3]);
img_preprocesada = f.clahe(img_suave, 0.02, [8 8]);

% 4. APLICACIÓN DE LOS ALGORITMOS DE SEGMENTACIÓN
% A) Canny
[bordes_canny, seg_canny] = s.canny(img_preprocesada, [], 1.2);

% B) Umbralización Global (T = 0.45)
[mascara_global, seg_global] = s.umbralGlobal(img_preprocesada, 0.45);

% C) Umbralización de Otsu
[mascara_otsu, seg_otsu, T_otsu] = s.otsu(img_preprocesada);

% D) K-Means (K = 3)
[etiquetas_km, seg_kmeans, mascara_km] = s.kmeans(img_preprocesada, 3);

% 5. MOSTRAR RESULTADOS
figure('Name', 'Resultados de Segmentación de Imágenes', 'NumberTitle', 'off');

subplot(2,3,1); imshow(imgOriginal); 
title('1. Imagen Original');

subplot(2,3,2); imshow(bordes_canny); 
title('2. Canny (Bordes)');

subplot(2,3,3); imshow(seg_global); 
title('3. Umbral Global (T=0.45)');

subplot(2,3,4); imshow(seg_otsu); 
title(sprintf('4. Otsu (T=%.2f)', T_otsu));

subplot(2,3,5); imshow(label2rgb(etiquetas_km)); 
title('5. Clústeres K-Means');

subplot(2,3,6); imshow(seg_kmeans); 
title('6. Segmentación K-Means');