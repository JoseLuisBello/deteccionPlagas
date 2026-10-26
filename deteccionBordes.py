import cv2
import numpy as np
import os
from tkinter import Tk, filedialog, messagebox
from datetime import datetime

def crear_carpeta_resultados():
    """Crea la carpeta de resultados si no existe"""
    carpeta = "resultados_segmentacion"
    if not os.path.exists(carpeta):
        os.makedirs(carpeta)
        print(f"Carpeta '{carpeta}' creada.")
    return carpeta

def seleccionar_imagen():
    """Abre un diálogo para seleccionar una imagen"""
    root = Tk()
    root.withdraw()  # Oculta la ventana principal de Tkinter
    root.attributes('-topmost', True)
    
    ruta = filedialog.askopenfilename(
        title="Selecciona una imagen de hoja de planta",
        filetypes=[
            ("Imágenes", "*.jpg *.jpeg *.png *.bmp *.tif *.tiff"),
            ("Todos los archivos", "*.*")
        ]
    )
    root.destroy()
    return ruta

def aplicar_canny(imagen_gris, umbral1=50, umbral2=150):
    """Detector de bordes de Canny"""
    # Aplicamos filtro de suavizado
    suavizada = cv2.GaussianBlur(imagen_gris, (5, 5), 0)
    bordes = cv2.Canny(suavizada, umbral1, umbral2)
    return bordes

def umbralizacion_global(imagen_gris, umbral=127):
    """Umbralización Global con un valor fijo"""
    _, binaria = cv2.threshold(imagen_gris, umbral, 255, cv2.THRESH_BINARY)
    return binaria

def umbralizacion_otsu(imagen_gris):
    """Umbralización de Otsu (un umbral automático)"""
    umbral, binaria = cv2.threshold(
        imagen_gris, 0, 255, 
        cv2.THRESH_BINARY + cv2.THRESH_OTSU
    )
    print(f"Umbral óptimo de Otsu encontrado: {umbral:.2f}")
    return binaria, umbral

def segmentacion_kmeans(imagen_color, k=3):
    """Segmentación con K-Means"""
    # Convertimos a float32 y redimensionamos a lista de píxeles
    pixeles = imagen_color.reshape((-1, 3))
    pixeles = np.float32(pixeles)

    # Criterios de parada
    criterios = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 100, 0.2)

    # Aplicamos K-Means
    _, etiquetas, centros = cv2.kmeans(
        pixeles, k, None, criterios, 10, cv2.KMEANS_RANDOM_CENTERS
    )

    # Convertimos centros a uint8 y reconstruimos la imagen
    centros = np.uint8(centros)
    imagen_segmentada = centros[etiquetas.flatten()]
    imagen_segmentada = imagen_segmentada.reshape(imagen_color.shape)

    return imagen_segmentada

def procesar_imagen(ruta_imagen):
    """Procesa la imagen con todos los métodos de segmentación"""
    
    # Cargar imagen
    imagen = cv2.imread(ruta_imagen)
    if imagen is None:
        messagebox.showerror("Error", "No se pudo cargar la imagen.")
        return

    # Convertir a escala de grises
    imagen_gris = cv2.cvtColor(imagen, cv2.COLOR_BGR2GRAY)

    # Crear carpeta de resultados
    carpeta = crear_carpeta_resultados()

    # Nombre base del archivo
    nombre_base = os.path.splitext(os.path.basename(ruta_imagen))[0]
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    prefijo = f"{nombre_base}_{timestamp}"

    # 1. Detector de bordes de Canny
    canny = aplicar_canny(imagen_gris, umbral1=50, umbral2=150)
    ruta_canny = os.path.join(carpeta, f"{prefijo}_canny.jpg")
    cv2.imwrite(ruta_canny, canny)
    print(f"Guardado: {ruta_canny}")

    # 2. Umbralización Global
    global_thresh = umbralizacion_global(imagen_gris, umbral=127)
    ruta_global = os.path.join(carpeta, f"{prefijo}_umbral_global.jpg")
    cv2.imwrite(ruta_global, global_thresh)
    print(f"Guardado: {ruta_global}")

    # 3. Umbralización de Otsu
    otsu, valor_otsu = umbralizacion_otsu(imagen_gris)
    ruta_otsu = os.path.join(carpeta, f"{prefijo}_otsu.jpg")
    cv2.imwrite(ruta_otsu, otsu)
    print(f"Guardado: {ruta_otsu}")

    # 4. K-Means
    kmeans = segmentacion_kmeans(imagen, k=3)
    ruta_kmeans = os.path.join(carpeta, f"{prefijo}_kmeans.jpg")
    cv2.imwrite(ruta_kmeans, kmeans)
    print(f"Guardado: {ruta_kmeans}")

    # Resultados
    # Redimensionamos un poco para visualización si son muy grandes
    def redimensionar(img, max_ancho=600):
        h, w = img.shape[:2]
        if w > max_ancho:
            escala = max_ancho / w
            return cv2.resize(img, (int(w*escala), int(h*escala)))
        return img

    cv2.imshow("Original", redimensionar(imagen))
    cv2.imshow("Canny", redimensionar(canny))
    cv2.imshow("Umbral Global", redimensionar(global_thresh))
    cv2.imshow("Otsu", redimensionar(otsu))
    cv2.imshow("K-Means", redimensionar(kmeans))

    print("\n=== Procesamiento terminado ===")
    print(f"Imágenes guardadas en la carpeta: '{carpeta}'")
    print("Presiona cualquier tecla en las ventanas de imagen para cerrar...")
    
    cv2.waitKey(0)
    cv2.destroyAllWindows()

    messagebox.showinfo(
        "Éxito", 
        f"Procesamiento completado.\n\n"
        f"Imágenes guardadas en:\n{os.path.abspath(carpeta)}\n\n"
        f"Umbral de Otsu: {valor_otsu:.1f}"
    )

def main():
    print("=" * 50)
    print("  Segmentación de Imágenes - Segundo Parcial")
    print("  Métodos: Canny | Umbral Global | Otsu | K-Means")
    print("=" * 50)

    ruta = seleccionar_imagen()

    if not ruta:
        print("No se seleccionó ninguna imagen. Saliendo...")
        return

    print(f"\nImagen seleccionada: {ruta}")
    procesar_imagen(ruta)

if __name__ == "__main__":
    main()