#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include "bmp.h"


unsigned char *LoadBMP(char *filename, bmpInfoHeader *bInfoHeader, int i) {
  FILE *f;
  bmpFileHeader header;     /* cabecera */
  unsigned char *imgdata;   /* datos de imagen */
  unsigned char *imgdata2;
  uint16_t type;            /* 2 bytes identificativos */
  clock_t t;
  
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
  imgdata = (unsigned char*) malloc(bInfoHeader->imgsize);
  imgdata2 = (unsigned char*) malloc(bInfoHeader->imgsize);
  
  if (imgdata == NULL) {
    printf("Fallo en el malloc, del fichero %s\n", filename);
    exit(0);
  }
  /* Nos situamos en donde empiezan los datos de imagen, lo indica el offset de la cabecera de fichero */
  fseek(f, header.offset, SEEK_SET);

  /* Leemos los datos de la imagen, tantos bytes como imgsize */
  fread(imgdata, bInfoHeader->imgsize,1, f);
  
  if (i == 1) {
      t = clock(); 
      blur(imgdata, bInfoHeader); 
      t = clock() - t; 
      double time_taken = ((double)t)/CLOCKS_PER_SEC;
      printf("blur took %f seconds to execute \n", time_taken);
  }
  else if (i == 2) {
      t = clock();
      BW(imgdata, bInfoHeader);
      t = clock() - t; 
      double time_taken = ((double)t)/CLOCKS_PER_SEC;
      printf("Black&White took %f seconds to execute \n", time_taken);
  }
  else if (i == 3) {
      int j;
      printf("elige el filtro mediante matriz de convolución:\n 1-resalto de bordes\n2-perfilado\n3-blur gaussiano\n4- sin cambios\n");
      scanf("%d", &j);
      t = clock();
      ConvMat(imgdata, imgdata2, bInfoHeader, j);
      t = clock() - t; 
      double time_taken = ((double)t)/CLOCKS_PER_SEC;
      printf("ConvMatrix took %f seconds to execute \n", time_taken);
      imgdata = imgdata2;
  }

  /* Cerramos el fichero */
  fclose(f);
  
  printf("el resultado se encuentra en el fichero aux.bmp");

  /* Devolvemos la imagen */
  return imgdata;
  
}

bmpInfoHeader *createInfoHeader(uint32_t width, uint32_t height, uint32_t ppp) {
  bmpInfoHeader *InfoHeader;

  InfoHeader = malloc(sizeof(bmpInfoHeader));
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
  fwrite(imgdata, InfoHeader->imgsize, 1, f);

  fclose(f);
}

void blur(unsigned char *imgdata, bmpInfoHeader *bInfoHeader) {
    
    int n,x,xx,y,yy,ile, avgR,avgB,avgG,B,G,R;
    int blurSize = 10;
    
    //KERNEL
    
    for(xx = 0; xx < bInfoHeader->width; xx++)
{
    for(yy = 0; yy < bInfoHeader->height; yy++)
    {
        avgB = avgG = avgR = 0;
        ile = 0;

        for(x = xx; x < bInfoHeader->width && x < xx + blurSize; x++)
        {


            for(y = yy; y < bInfoHeader->height && y < yy + blurSize; y++)
            {
                avgB += imgdata[x*3 + y*bInfoHeader->width*3 + 0];
                avgG += imgdata[x*3 + y*bInfoHeader->width*3 + 1];
                avgR += imgdata[x*3 + y*bInfoHeader->width*3 + 2];
                ile++;
            }
        }

        avgB = avgB / ile;
        avgG = avgG / ile;
        avgR = avgR / ile;

        imgdata[xx*3 + yy*bInfoHeader->width*3 + 0] = avgB;
        imgdata[xx*3 + yy*bInfoHeader->width*3 + 1] = avgG;
        imgdata[xx*3 + yy*bInfoHeader->width*3 + 2] = avgR;
    }
}

    
    
}

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

void ConvMat(unsigned char *imgdata, unsigned char *imgdata2, bmpInfoHeader *bInfoHeader, int j) {
    
    int xx, yy, x, y;
    float avgB, avgR, avgG;
    float mat[3][3];
    if (j == 1) {
        BW(imgdata2, bInfoHeader);
        BW(imgdata, bInfoHeader);
        mat[0][0] = -1.;
        mat[0][1] = -1.;
        mat[0][2] = -1.;
        mat[1][0] = -1.;
        mat[1][1] = 8.;
        mat[1][2] = -1.;
        mat[2][0] = -1.;
        mat[2][1] = -1.;
        mat[2][2] = -1.;
    }
    else if (j == 2) {
        mat[0][0] = 0.;
        mat[0][1] = -1.;
        mat[0][2] = 0.;
        mat[1][0] = -1.;
        mat[1][1] = 5.;
        mat[1][2] = -1.;
        mat[2][0] = 0.;
        mat[2][1] = -1.;
        mat[2][2] = 0.;
    }
    else if (j == 3) {
        mat[0][0] = 1./16.;
        mat[0][1] = 2./16.;
        mat[0][2] = 1./16.;
        mat[1][0] = 2./16.;
        mat[1][1] = 4./16.;
        mat[1][2] = 2./16.;
        mat[2][0] = 1./16.;
        mat[2][1] = 2./16.;
        mat[2][2] = 1./16.;
    }
    else {
        mat[0][0] = 0.;
        mat[0][1] = 0.;
        mat[0][2] = 0.;
        mat[1][0] = 0.;
        mat[1][1] = 1.;
        mat[1][2] = 0.;
        mat[2][0] = 0.;
        mat[2][1] = 0.;
        mat[2][2] = 0.;
    }
    
    //KERNEL
    
    for(xx = 1; xx < bInfoHeader->width - 1; xx++)
    {
    for(yy = 1; yy < bInfoHeader->height - 1; yy++)
    {
        avgB = avgG = avgR = 0;
        
        for(x = -1; x < 2; x++)
        {
            for(y = -1; y < 2; y++)
            {
                    avgB += imgdata[(xx + x)*3 + (y + yy)*bInfoHeader->width*3 + 0] * mat[x + 1][y + 1];
                    avgG += imgdata[(xx + x)*3 + (y + yy)*bInfoHeader->width*3 + 1] * mat[x + 1][y + 1];
                    avgR += imgdata[(xx + x)*3 + (y + yy)*bInfoHeader->width*3 + 2] * mat[x + 1][y + 1];
            }
        }
        imgdata2[xx*3 + yy*bInfoHeader->width*3 + 0] = avgB;
        imgdata2[xx*3 + yy*bInfoHeader->width*3 + 1] = avgG;
        imgdata2[xx*3 + yy*bInfoHeader->width*3 + 2] = avgR;
    }
}
}


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

