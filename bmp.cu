#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <time.h>
#define SIZE 32

typedef struct bmpFileHeaderStruct {
  /* 2 bytes de identificación */
  uint32_t size;        /* Tamaño del archivo */
  uint16_t resv1;       /* Reservado */
  uint16_t resv2;       /* Reservado */
  uint32_t offset;      /* Offset hasta hasta los datos de imagen */
} bmpFileHeader;

typedef struct bmpInfoHeaderStruct {
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


void BW(unsigned char *imgdata, bmpInfoHeader *bInfoHeader) {
    
    float color;
    int x, y;

        //KERNEL
        for(x = 0; x < bInfoHeader->width; x++)
        {
            for(y = 0; y < bInfoHeader->height; y++)
            {
                color += imgdata[x*3 + y*bInfoHeader->width*3 + 0] * 0.114;
                color += imgdata[x*3 + y*bInfoHeader->width*3 + 1] * 0.587;
                color += imgdata[x*3 + y*bInfoHeader->width*3 + 2] * 0.299;
                color /= 3;
                imgdata[x*3 + y*bInfoHeader->width*3 + 0] = color;
                imgdata[x*3 + y*bInfoHeader->width*3 + 1] = color;
                imgdata[x*3 + y*bInfoHeader->width*3 + 2] = color;
            }
        }

        /*imgdata[xx*3 + yy*bInfoHeader->width*3 + 0] = avgB;
        imgdata[xx*3 + yy*bInfoHeader->width*3 + 1] = avgG;
        imgdata[xx*3 + yy*bInfoHeader->width*3 + 2] = avgR;*/

}



__global__ void ConvMatKernel(unsigned char *img_device, unsigned char *img_device2, uint32_t width_image, uint32_t height_image, int j, float *mat) {
    //Hay que pasarle la matriz
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int i = width_image * row + col;
    float avgB, avgG, avgR;
    int x, y;

    avgB = avgG = avgR = 0;

    if (i < (width_image * height_image)) {          
        for(x = -1; x < 2; x++) {
          if (row == 0 && x == -1) {
              x = 0;
          }
          else if (row == height_image - 1) {
              if (x > 0) break;
          }
          for(y = -1; y < 2; y++) {
              if (col == 0 && y == -1) y = 0;
              if (col == width_image - 1 && y == 1) break;
              avgB += img_device[(col + y)*3 + (x + row) * width_image*3 + 0] * mat[((x + 1) * 3) + y + 1];
              avgG += img_device[(col + y)*3 + (x + row) * width_image*3 + 1] * mat[((x + 1) * 3) + y + 1];
              avgR += img_device[(col + y)*3 + (x + row) * width_image*3 + 2] * mat[((x + 1) * 3) + y + 1];
          }
        }
        img_device2[col*3 + row*width_image*3 + 0] = avgB;
        img_device2[col*3 + row*width_image*3 + 1] = avgG;
        img_device2[col*3 + row*width_image*3 + 2] = avgR;
    }
}

__global__ void blurKernel(unsigned char *img_device, unsigned char *img_device2, uint32_t width_image, uint32_t height_image) {

    int x,y,ile, avgR,avgB,avgG;
    int blurSize = 10;
    avgB = avgG = avgR = 0;
    ile = 0;
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int i = width_image * row + col;

    if (i < (width_image * height_image)) {
        for(x = col; x < width_image && x < col + blurSize; x++)
        {
            for(y = row; y < height_image && y < row + blurSize; y++)
            {
                avgB += img_device2[x*3 + y*width_image*3 + 0];
                avgG += img_device2[x*3 + y*width_image*3 + 1];
                avgR += img_device2[x*3 + y*width_image*3 + 2];
                ile++;
            }
        }
        avgB = avgB / ile;
        avgG = avgG / ile;
        avgR = avgR / ile;

        img_device[col*3 + row*width_image*3 + 0] = avgB;
        img_device[col*3 + row*width_image*3 + 1] = avgG;
        img_device[col*3 + row*width_image*3 + 2] = avgR;
    }
}


//Kernel BW


__global__ void BWkernel(unsigned char *img_device, uint32_t n) {
    float color;
    color = 0.0f;
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        color += img_device[i*3 + 0] * 0.114;
        color += img_device[i*3 + 1] * 0.587;
        color += img_device[i*3 + 2] * 0.299;
        color /= 3;
        img_device[i*3 + 0] = color;
        img_device[i*3 + 1] = color;
        img_device[i*3 + 2] = color;
    }
  }

  void CheckCudaError(char sms[], int line);


bmpInfoHeader *createInfoHeader(uint32_t width, uint32_t height, uint32_t ppp) {
	
  bmpInfoHeader *InfoHeader;

  //InfoHeader = malloc(sizeof(InfoHeader));
  if (InfoHeader == NULL) return NULL; 
  InfoHeader->headersize = sizeof(bmpInfoHeader);
  InfoHeader->width = width;
  InfoHeader->height = height;
  InfoHeader->planes = 1;
  InfoHeader->bpp = 24;
  InfoHeader->compress = 0;
  /* 3 bytes por pixel, width*height pixels, el tamaño de las filas ha de ser multiplo de 4 */
  InfoHeader->imgsize = ((width*3 + 3) / 4) * 4 * height;        
  InfoHeader->bpmx = (unsigned) ((double)ppp*100/2.54);
  InfoHeader->bpmy= InfoHeader->bpmx;          /* Misma resolucion vertical y horiontal */
  InfoHeader->colors = 0;
  InfoHeader->imxtcolors = 0;

  return InfoHeader;
}

void CheckCudaError(char sms[], int line) {
  cudaError_t error;
 
  error = cudaGetLastError();
  if (error) {
    printf("(ERROR) %s - %s in %s at line %d\n", sms, cudaGetErrorString(error), __FILE__, line);
    exit(EXIT_FAILURE);
  }
}




unsigned char *LoadBMP(char *filename, bmpInfoHeader *bInfoHeader, int i) {
  FILE *f;
  bmpFileHeader header;     /* cabecera */
  unsigned char *imgdata_h;   /* datos de imagen */
  unsigned char *imgdata2_h;
  unsigned char *imgdata_d;   
  unsigned char *imgdata2_d;
  uint16_t type;            /* 2 bytes identificativos */
  //Para el kernel
  unsigned int N;
  unsigned int numBytes;
  unsigned int nBlocks, nThreads;
  float TiempoTotal, TiempoKernel;
  cudaEvent_t E0, E1, E2, E3;

  f=fopen (filename, "r");
  if (!f) { /* Si no podemos leer, no hay imagen */
    printf("NO se puede abrir el fichero %s\n", filename);
    return NULL;        
  } 

  /* Leemos los dos primeros bytes y comprobamos el formato */
  fread(&type, sizeof(uint16_t), 1, f);
  if (type !=0x4D42) {       
    fclose(f);
    printf("%s NO es una imagen BMP\n", filename);
    return NULL;
  }

  /* Leemos la cabecera del fichero */
  fread(&header, sizeof(bmpFileHeader), 1, f);

  printf("File size: %u\n", header.size);
  printf("Reservado: %u\n", header.resv1);
  printf("Reservado: %u\n", header.resv2);
  printf("Offset:    %u\n", header.offset);

  /* Leemos la cabecera de información del BMP */
  fread(bInfoHeader, sizeof(bmpInfoHeader), 1, f);

  /* Reservamos memoria para la imagen, lo que indique imgsize */
  if (bInfoHeader->imgsize == 0) bInfoHeader->imgsize = ((bInfoHeader->width*3 +3) / 4) * 4 * bInfoHeader->height;
  imgdata_h = (unsigned char*) malloc(bInfoHeader->imgsize);
  imgdata2_h = (unsigned char*) malloc(bInfoHeader->imgsize);
  
  if (imgdata_h == NULL) {
    printf("Fallo en el malloc, del fichero %s\n", filename);
    exit(0);
  }
  /* Nos situamos en donde empiezan los datos de imagen, lo indica el offset de la cabecera de fichero */
  fseek(f, header.offset, SEEK_SET);

  /* Leemos los datos de la imagen, tantos bytes como imgsize */
  fread(imgdata_h, bInfoHeader->imgsize,1, f);
  
  if (i == 1) {
      nThreads = SIZE;
      N = bInfoHeader->imgsize;
      // numero de Blocks en cada dimension 
      uint32_t nBlocksWidth = bInfoHeader->width / nThreads;
      uint32_t nBlocksHeight = bInfoHeader->height / nThreads;

      dim3 dimGrid(nBlocksWidth, nBlocksHeight, 1);
      dim3 dimBlock(nThreads, nThreads, 1);

      cudaEventCreate(&E0);
      cudaEventCreate(&E1);
      cudaEventCreate(&E2);
      cudaEventCreate(&E3);

      cudaEventRecord(E0, 0);
      cudaEventSynchronize(E0);

      cudaMalloc((unsigned char**)&imgdata_d, bInfoHeader->imgsize);
      cudaMalloc((unsigned char**)&imgdata2_d, bInfoHeader->imgsize);
      CheckCudaError((char *) "Obtener Memoria en el device", __LINE__);

      cudaMemcpy(imgdata_d, imgdata_h, bInfoHeader->imgsize, cudaMemcpyHostToDevice);
      cudaMemcpy(imgdata2_d, imgdata_h, bInfoHeader->imgsize, cudaMemcpyHostToDevice);
      CheckCudaError((char *) "Copiar Datos Host --> Device", __LINE__);

      cudaEventRecord(E1, 0);
      cudaEventSynchronize(E1);
      
      blurKernel<<<dimGrid, dimBlock>>>(imgdata_d, imgdata2_d, bInfoHeader->width, bInfoHeader->height);
      CheckCudaError((char *) "Invocar Kernel", __LINE__);

      cudaEventRecord(E2, 0);
      cudaEventSynchronize(E2); 

      cudaMemcpy(imgdata_h, imgdata_d, bInfoHeader->imgsize, cudaMemcpyDeviceToHost);
      CheckCudaError((char *) "Copiar Datos Device --> Host", __LINE__);

      cudaEventRecord(E3, 0);
      cudaEventSynchronize(E3);
      cudaEventElapsedTime(&TiempoTotal,  E0, E3);
      cudaEventElapsedTime(&TiempoKernel, E1, E2);
      printf("\nKERNEL BlackAndWhiteFilter\n");
      printf("Dimensiones: %d\n",N);
      printf("nThreads: %dx%d (%d)\n", nThreads, nBlocks, nThreads * nBlocks);
      printf("nBlocks: %d\n", nBlocks);
      printf("Tiempo Global: %4.6f milseg\n", TiempoTotal);
      printf("Tiempo Kernel: %4.6f milseg\n", TiempoKernel);
      printf("Rendimiento Global: %4.2f GFLOPS\n", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoTotal));
      printf("Rendimiento Kernel: %4.2f GFLOPS\n", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoKernel));

      cudaEventDestroy(E0); cudaEventDestroy(E1); cudaEventDestroy(E2); cudaEventDestroy(E3);
      cudaFree(imgdata_d);
      cudaFree(imgdata2_d);
  }
  else if (i == 2) {
      // numero de Threads en cada dimension 
    nThreads = SIZE;
    N = bInfoHeader->imgsize;
    // numero de Blocks en cada dimension 
    nBlocks = N / nThreads;
  
	  dim3 dimGrid(nBlocks, 1, 1);
	  dim3 dimBlock(nThreads, 1, 1);
    cudaEventCreate(&E0);
    cudaEventCreate(&E1);
    cudaEventCreate(&E2);
    cudaEventCreate(&E3);

    cudaEventRecord(E0, 0);
    cudaEventSynchronize(E0);

	  cudaMalloc((unsigned char**)&imgdata_d, bInfoHeader->imgsize);
    CheckCudaError((char *) "Obtener Memoria en el device", __LINE__);
	  //cudaMalloc((unsigned char**)&imgdata2_d, bInfoHeader->imgsize);
	  cudaMemcpy(imgdata_d, imgdata_h, bInfoHeader->imgsize, cudaMemcpyHostToDevice);
    CheckCudaError((char *) "Copiar Datos Host --> Device", __LINE__);

	  //cudaMemcpy(imgdata2_d, imgdata2_h, bInfoHeader->imgsize, cudaMemcpyHostToDevice);
    cudaEventRecord(E1, 0);
    cudaEventSynchronize(E1);
      
	  BWkernel<<<nBlocks, nThreads>>>(imgdata_d, (bInfoHeader->width * bInfoHeader->height));
    CheckCudaError((char *) "Invocar Kernel", __LINE__);

      //BW(imgdata_h, bInfoHeader);
    cudaEventRecord(E2, 0);
    cudaEventSynchronize(E2); 

	  cudaMemcpy(imgdata_h, imgdata_d, bInfoHeader->imgsize, cudaMemcpyDeviceToHost);
    CheckCudaError((char *) "Copiar Datos Device --> Host", __LINE__);

    cudaEventRecord(E3, 0);
    cudaEventSynchronize(E3);
    
    cudaEventElapsedTime(&TiempoTotal,  E0, E3);
    cudaEventElapsedTime(&TiempoKernel, E1, E2);
    printf("\nKERNEL BlackAndWhiteFilter\n");
    printf("Dimensiones: %d\n",N);
    printf("nThreads: %dx%d (%d)\n", nThreads, nBlocks, nThreads * nBlocks);
    printf("nBlocks: %d\n", nBlocks);
    printf("Tiempo Global: %4.6f milseg\n", TiempoTotal);
    printf("Tiempo Kernel: %4.6f milseg\n", TiempoKernel);
    printf("Rendimiento Global: %4.2f GFLOPS\n", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoTotal));
    printf("Rendimiento Kernel: %4.2f GFLOPS\n", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoKernel));

    cudaEventDestroy(E0); cudaEventDestroy(E1); cudaEventDestroy(E2); cudaEventDestroy(E3);
    cudaFree(imgdata_d);
      //printf("Black&White took %f seconds to execute \n", time_taken);
  }
  else if (i == 3) {
      float mat[9];
      float *mat_d;
      //BW(imgdata_h, bInfoHeader);
      int j = 3;
      if (j == 1) {
          mat[0] = -1.;
          mat[1] = -1.;
          mat[2] = -1.;
          mat[3] = -1.;
          mat[4] = 8.;
          mat[5] = -1.;
          mat[6] = -1.;
          mat[7] = -1.;
          mat[8] = -1.;
      }
      else if (j == 2) {
          mat[0] = 0.;
          mat[1] = -1.;
          mat[2] = 0.;
          mat[3] = -1.;
          mat[4] = 5.;
          mat[5] = -1.;
          mat[6] = 0.;
          mat[7] = -1.;
          mat[8] = 0.;
      }
      else if (j == 3) {
          mat[0] = 1./16.;
          mat[1] = 2./16.;
          mat[2] = 1./16.;
          mat[3] = 2./16.;
          mat[4] = 4./16.;
          mat[5] = 2./16.;
          mat[6] = 1./16.;
          mat[7] = 2./16.;
          mat[8] = 1./16.;
      }
      else {
          mat[0] = 0.;
          mat[1] = 0.;
          mat[2] = 0.;
          mat[3] = 0.;
          mat[4] = 1.;
          mat[5] = 0.;
          mat[6] = 0.;
          mat[7] = 0.;
          mat[8] = 0.;
      }
      nThreads = SIZE;
      N = bInfoHeader->imgsize;
      // numero de Blocks en cada dimension 
      uint32_t nBlocksWidth = bInfoHeader->width / nThreads;
      uint32_t nBlocksHeight = bInfoHeader->height / nThreads;

      dim3 dimGrid(nBlocksWidth, nBlocksHeight, 1);
      dim3 dimBlock(nThreads, nThreads, 1);

      cudaEventCreate(&E0);
      cudaEventCreate(&E1);
      cudaEventCreate(&E2);
      cudaEventCreate(&E3);

      cudaEventRecord(E0, 0);
      cudaEventSynchronize(E0);

      cudaMalloc((unsigned char**)&imgdata_d, bInfoHeader->imgsize);
      cudaMalloc((unsigned char**)&imgdata2_d, bInfoHeader->imgsize);
      cudaMalloc((float**)&mat_d, 9 * sizeof(float));
      CheckCudaError((char *) "Obtener Memoria en el device", __LINE__);

      cudaMemcpy(imgdata_d, imgdata_h, bInfoHeader->imgsize, cudaMemcpyHostToDevice);
      cudaMemcpy(imgdata2_d, imgdata_h, bInfoHeader->imgsize, cudaMemcpyHostToDevice);
      cudaMemcpy(mat_d, mat, 9 * sizeof(float), cudaMemcpyHostToDevice);
      CheckCudaError((char *) "Copiar Datos Host --> Device", __LINE__);

      cudaEventRecord(E1, 0);
      cudaEventSynchronize(E1);
      
      ConvMatKernel<<<dimGrid, dimBlock>>>(imgdata_d, imgdata2_d, bInfoHeader->width, bInfoHeader->height, j, mat_d);
      CheckCudaError((char *) "Invocar Kernel", __LINE__);

      cudaEventRecord(E2, 0);
      cudaEventSynchronize(E2); 

      cudaMemcpy(imgdata_h, imgdata2_d, bInfoHeader->imgsize, cudaMemcpyDeviceToHost);
      CheckCudaError((char *) "Copiar Datos Device --> Host", __LINE__);

      cudaEventRecord(E3, 0);
      cudaEventSynchronize(E3);
      cudaEventElapsedTime(&TiempoTotal,  E0, E3);
      cudaEventElapsedTime(&TiempoKernel, E1, E2);
      printf("\nKERNEL BlackAndWhiteFilter\n");
      printf("Dimensiones: %d\n",N);
      printf("nThreads: %dx%d (%d)\n", nThreads, nBlocks, nThreads * nBlocks);
      printf("nBlocks: %d\n", nBlocks);
      printf("Tiempo Global: %4.6f milseg\n", TiempoTotal);
      printf("Tiempo Kernel: %4.6f milseg\n", TiempoKernel);
      printf("Rendimiento Global: %4.2f GFLOPS\n", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoTotal));
      printf("Rendimiento Kernel: %4.2f GFLOPS\n", (2.0 * (float) N * (float) N * (float) N) / (1000000.0 * TiempoKernel));

      cudaEventDestroy(E0); cudaEventDestroy(E1); cudaEventDestroy(E2); cudaEventDestroy(E3);
      cudaFree(imgdata_d);
      cudaFree(imgdata2_d);
      cudaFree(mat_d);
  }

  /* Cerramos el fichero */
  fclose(f);
  
  printf("el resultado se encuentra en el fichero aux.bmp");

  /* Devolvemos la imagen */
  return imgdata_h;
  
}

void SaveBMP(char *filename, bmpInfoHeader *InfoHeader, unsigned char *imgdata) {
  bmpFileHeader header;
  FILE *f;
  uint16_t type;
  
  f=fopen(filename, "w+");

  header.size = InfoHeader->imgsize + sizeof(bmpFileHeader) + sizeof(bmpInfoHeader) + 2;
  header.resv1 = 0; 
  header.resv2 = 0; 
  /* El offset será el tamaño de las dos cabeceras + 2 (información de fichero)*/
  header.offset=sizeof(bmpFileHeader)+sizeof(bmpInfoHeader)+2;

  /* Escribimos la identificación del archivo */
  type=0x4D42;
  fwrite(&type, sizeof(type),1,f);

  /* Escribimos la cabecera de fichero */
  fwrite(&header, sizeof(bmpFileHeader),1,f);

  /* Escribimos la información básica de la imagen */
  fwrite(InfoHeader, sizeof(bmpInfoHeader),1,f);
  /* Escribimos la imagen */
  printf("%f \n",InfoHeader->imgsize);
  fwrite(imgdata, InfoHeader->imgsize, 1, f);
  fclose(f);
}


//kernel Function, para esta función, necesitamos tanto la fila como la columna en la que actuará nuestro thread en cuestion.
//Ademas tenemos que tener dos copias de imgdata, en uno tendramos los nuevos datos, y la otra la utilizaremos para calcular la primera.


void DisplayInfo(char *FileName, bmpInfoHeader *InfoHeader)
{
  printf("\n");
  printf("Informacion de %s\n", FileName);
  printf("Tamaño de la cabecera: %u bytes\n", InfoHeader->headersize);
  printf("Anchura:               %d pixels\n", InfoHeader->width);
  printf("Altura:                %d pixels\n", InfoHeader->height);
  printf("Planos (1):            %d\n", InfoHeader->planes);
  printf("Bits por pixel:        %d\n", InfoHeader->bpp);
  printf("Compresion:            %d\n", InfoHeader->compress);
  printf("Tamaño de la imagen:   %u bytes\n", InfoHeader->imgsize);
  printf("Resolucion horizontal: %u px/m\n", InfoHeader->bpmx);
  printf("Resolucion vertical:   %u px/m\n", InfoHeader->bpmy);
  if (InfoHeader->bpmx == 0) 
    InfoHeader->bpmx = (unsigned) ((double)24*100/2.54);
  if (InfoHeader->bpmy == 0) 
    InfoHeader->bpmy = (unsigned) ((double)24*100/2.54);

  printf("Colores en paleta:     %d\n", InfoHeader->colors);
  printf("Colores importantes:   %d\n", InfoHeader->imxtcolors);
}

int main(int argc, char** argv) {

  bmpInfoHeader header;

  unsigned char *image;
  
  //int i;
  
  printf("introduce numero del 1 al 4\n1-blur\n2-black and white filter\n3-matriz de convolucion\n4-exit\n");
  
  //scanf("%d", &i);

  image = LoadBMP("./canicas.bmp", &header, 3);
  //DisplayInfo("./canicas.bmp", &header);

  SaveBMP("./auxmat.bmp", &header, image);

}



