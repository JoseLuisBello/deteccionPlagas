clc;
clear;
close all;

%% ==========================================
% 1. SELECCIONAR DATASET
% ==========================================

datasetRoot = uigetdir( ...
    pwd, ...
    'Selecciona la carpeta New Plant Diseases Dataset(Augmented)' ...
);

if datasetRoot == 0
    error('No se seleccionó ninguna carpeta.');
end

%% ==========================================
% 2. RUTAS
% ==========================================

trainFolder = fullfile(datasetRoot, 'train');
validFolder = fullfile(datasetRoot, 'valid');
testFolder  = fullfile(datasetRoot, 'test');

if ~isfolder(trainFolder)
    error('No se encontró la carpeta train.');
end

if ~isfolder(validFolder)
    error('No se encontró la carpeta valid.');
end

if ~isfolder(testFolder)
    error('No se encontró la carpeta test.');
end

%% ==========================================
% 3. LEER DATASET
% ==========================================

imdsTrain = imageDatastore( ...
    trainFolder, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

imdsValid = imageDatastore( ...
    validFolder, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

imdsTest = imageDatastore( ...
    testFolder, ...
    'IncludeSubfolders', true);

%% ==========================================
% 4. CANTIDAD DE IMÁGENES
% ==========================================

numTrain = numel(imdsTrain.Files);
numValid = numel(imdsValid.Files);
numTest  = numel(imdsTest.Files);

numTotal = numTrain + numValid + numTest;

fprintf('\n');
fprintf('==========================================\n');
fprintf('       ESTADÍSTICAS DEL DATASET\n');
fprintf('==========================================\n');

fprintf('Entrenamiento : %d\n', numTrain);
fprintf('Validación    : %d\n', numValid);
fprintf('Prueba        : %d\n', numTest);
fprintf('TOTAL         : %d\n', numTotal);

%% ==========================================
% 5. CATEGORÍAS
% ==========================================

tablaTrain = countEachLabel(imdsTrain);

numCategorias = height(tablaTrain);

fprintf('\nNúmero de categorías: %d\n', numCategorias);

%% ==========================================
% 6. TABLA DE CATEGORÍAS
% ==========================================

fprintf('\n');
fprintf('Imágenes por categoría:\n');

disp(tablaTrain);

%% ==========================================
% 7. FORMATOS
% ==========================================

archivos = [ ...
    imdsTrain.Files;
    imdsValid.Files;
    imdsTest.Files
];

extensiones = strings(numel(archivos), 1);

for i = 1:numel(archivos)

    [~, ~, ext] = fileparts(archivos{i});

    extensiones(i) = lower(ext);

end

formatos = unique(extensiones);

fprintf('\nFormatos encontrados:\n');

for i = 1:numel(formatos)

    fprintf('%s\n', formatos(i));

end

%% ==========================================
% 8. DIMENSIONES
% ==========================================

numMuestras = min(100, numel(archivos));

anchos = zeros(numMuestras,1);
altos = zeros(numMuestras,1);

for i = 1:numMuestras

    info = imfinfo(archivos{i});

    anchos(i) = info.Width;
    altos(i) = info.Height;

end

fprintf('\n');
fprintf('Dimensiones de las imágenes analizadas:\n');

fprintf('Ancho mínimo : %d px\n', min(anchos));
fprintf('Ancho máximo : %d px\n', max(anchos));

fprintf('Alto mínimo  : %d px\n', min(altos));
fprintf('Alto máximo  : %d px\n', max(altos));

%% ==========================================
% 9. RGB / ESCALA DE GRISES
% ==========================================

rgb = 0;
gris = 0;

for i = 1:numMuestras

    imagen = imread(archivos{i});

    if ndims(imagen) == 3
        rgb = rgb + 1;
    else
        gris = gris + 1;
    end

end

fprintf('\n');
fprintf('Escala de color en la muestra:\n');

fprintf('RGB             : %d\n', rgb);
fprintf('Escala de grises: %d\n', gris);

%% ==========================================
% 10. GRÁFICA POR CATEGORÍA
% ==========================================

figure;

barh(tablaTrain.Count);

xlabel('Número de imágenes');
ylabel('Categoría');

title('Distribución de imágenes de entrenamiento');

yticks(1:height(tablaTrain));
yticklabels(tablaTrain.Label);

grid on;

%% ==========================================
% 11. MOSTRAR EJEMPLOS
% ==========================================

figure;

numImagenes = min(9, numel(imdsTrain.Files));

for i = 1:numImagenes

    imagen = readimage(imdsTrain, i);

    subplot(3,3,i);

    imshow(imagen);

    title(string(imdsTrain.Labels(i)), ...
        'Interpreter','none');

end

sgtitle('Ejemplos del conjunto de entrenamiento');

%% ==========================================
% FIN
% ==========================================

fprintf('\n');
fprintf('==========================================\n');
fprintf('      ANÁLISIS TERMINADO CORRECTAMENTE\n');
fprintf('==========================================\n');