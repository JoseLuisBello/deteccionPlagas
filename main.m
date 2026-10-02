% =========================================================================
% SCRIPT PRINCIPAL: DESGLOSE PASO A PASO POR CADA COMBINACIÓN
% =========================================================================
clc; clear; close all;

% 1. SELECCIONAR IMAGEN DE HOJA
[archivo, ruta] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png;*.bmp', 'Archivos de imagen (*.jpg, *.png, *.bmp)'}, ...
    'Selecciona una imagen de hoja con plaga');
if isequal(archivo, 0)
    disp('Selección cancelada.');
    return;
end

% 2. LEER Y VERIFICAR FORMATO
imgOriginal = imread(fullfile(ruta, archivo));
if size(imgOriginal, 3) == 1
    imgOriginal = cat(3, imgOriginal, imgOriginal, imgOriginal);
end

% 3. CARGAR MÓDULO DE FILTROS
f = filtros();
fprintf('Procesando y generando ventanas independientes para cada combinación...\n');

% =========================================================================
% COMBINACIÓN 1: PIPELINE COMPLETO SECUENCIAL
% =========================================================================
paso1_1 = f.mediana(imgOriginal, [3 3]); 
paso1_2 = f.clahe(paso1_1, 0.02, [8 8]); 
paso1_3 = f.gaussiano(paso1_2, 1.0); 
res1    = f.highboost(paso1_3, 1.5, 0.8); % Realce de textura balanceado

figure('Name', 'VENTANA 1: Combinación 1 - Pipeline Completo', 'NumberTitle', 'off');
subplot(2,3,1); imshow(imgOriginal); title('1. Original');
subplot(2,3,2); imshow(paso1_1);      title('2. Mediana (3x3)');
subplot(2,3,3); imshow(paso1_2);      title('3. CLAHE');
subplot(2,3,4); imshow(paso1_3);      title('4. Gaussiano (\sigma=1.0)');
subplot(2,3,5); imshow(res1);         title('5. RESULTADO FINAL (Highboost)', 'Color', 'r');

% =========================================================================
% COMBINACIÓN 2: PRESERVACIÓN DE MICRO-LESIONES Y DETALLES
% =========================================================================
paso2_1 = f.mediana(imgOriginal, [3 3]); 
paso2_2 = f.ecualizacionHistograma(paso2_1); 
res2    = f.highboost(paso2_2, 1.0, 1.0); 

figure('Name', 'VENTANA 2: Combinación 2 - Preservación de Detalles', 'NumberTitle', 'off');
subplot(2,2,1); imshow(imgOriginal); title('1. Original');
subplot(2,2,2); imshow(paso2_1);      title('2. Mediana (3x3)');
subplot(2,2,3); imshow(paso2_2);      title('3. Ecualización Histograma');
subplot(2,2,4); imshow(res2);         title('4. RESULTADO FINAL (Highboost)', 'Color', 'r');

% =========================================================================
% COMBINACIÓN 3: CONTORNO FUERTE Y AISLAMIENTO DE TEXTURA
% =========================================================================
paso3_1 = f.promedio_pesado(imgOriginal); 
paso3_2 = f.clahe(paso3_1, 0.025, [8 8]); 
paso3_3 = f.mediana(paso3_2, [3 3]); 
res3    = f.laplaciono4(paso3_3); 

figure('Name', 'VENTANA 3: Combinación 3 - Contorno Fuerte y Aislamiento', 'NumberTitle', 'off');
subplot(2,3,1); imshow(imgOriginal); title('1. Original');
subplot(2,3,2); imshow(paso3_1);      title('2. Promedio Pesado');
subplot(2,3,3); imshow(paso3_2);      title('3. CLAHE');
subplot(2,3,4); imshow(paso3_3);      title('4. Mediana (3x3)');
subplot(2,3,5); imshow(res3);         title('5. RESULTADO FINAL (Laplaciano 4)', 'Color', 'r');

disp('Procesamiento completado.');