typedef struct bmpFileHeader {
  /* 2 bytes de identificación */
  uint32_t size;        /* Tamaño del archivo */
  uint16_t resv1;       /* Reservado */
  uint16_t resv2;       /* Reservado */
  uint32_t offset;      /* Offset hasta hasta los datos de imagen */
} bmpFileHeader;

typedef struct bmpInfoHeader {
  uint32_t headersize;  /* Tamaño de la cabecera */
  uint32_t width;       /* Ancho */
  uint32_t height;      /* Alto */
  uint16_t planes;      /* Planos de color (Siempre 1) */
  uint16_t bpp;         /* bits por pixel */
  uint32_t compress;    /* compresion */
  uint32_t imgsize;     /* tamaño de los datos de imagen */
  uint32_t bpmx;        /* Resolucion X en bits por metro */
  uint32_t bpmy;        /* Resolucion Y en bits por metro */
  uint32_t colors;      /* colors used en la paleta */
  uint32_t imxtcolors;  /* Colores importantes. 0 si son todos */
} bmpInfoHeader;

void SaveBMP(char *filename, bmpInfoHeader *info, unsigned char *imgdata);
unsigned char *LoadBMP(char *filename, bmpInfoHeader *bInfoHeader, int i);
void blur(unsigned char *imgdata, bmpInfoHeader *bInfoHeader);
void BW(unsigned char *imgdata, bmpInfoHeader *bInfoHeader);
void ConvMat(unsigned char *imgdata, unsigned char *imgdata2, bmpInfoHeader *bInfoHeader, int j, float mat[3][3]);
bmpInfoHeader *createInfoHeader(uint32_t width, uint32_t height, uint32_t ppp);
void DisplayInfo(char *Filename, bmpInfoHeader *info);

