#include <stdio.h>
#include <stdint.h>
#include "bmp.h"

/*
void SaveBMP(char *filename, bmpInfoHeader *info, unsigned char *imgdata);
unsigned char *LoadBMP(char *filename, bmpInfoHeader *bInfoHeader);
bmpInfoHeader *createInfoHeader(uint32_t width, uint32_t height, uint32_t ppp);
void DisplayInfo(char *Filename, bmpInfoHeader *info);
*/

int main(int argc, char** argv) {

  bmpInfoHeader header;

  unsigned char *image;
  
  int i;
  
  printf("introduce numero del 1 al 4\n1-blur\n2-black and white filter\n3-matriz de convolucion\n4-pene\n");
  
  scanf("%d", &i);

  image = LoadBMP("canicas.bmp", &header, i);
  DisplayInfo("canicas.bmp", &header);

  SaveBMP("aux.bmp", &header, image);


}


