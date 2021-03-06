#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include "bmp.h"

int blur(char* input, char *output) {

  //variable dec:
  FILE *fp,*out;
  bitmap_header* hp;
  int n,x,xx,y,yy,ile, avgR,avgB,avgG,B,G,R;
  unsigned char *data;
  int blurSize = 5;


  //Open input file:
  fp = fopen(input, "r");
  if(fp==NULL){
    //cleanup
  }

  //Read the input file headers:
  hp=(bitmap_header*)malloc(sizeof(bitmap_header));
  if(hp==NULL)
    return 3;

  n=fread(hp, sizeof(bitmap_header), 1, fp);
  if(n<1){
    //cleanup
  }
  //Read the data of the image:
  data = (char*)malloc(sizeof(char)*hp->bitmapsize);
  if(data==NULL){
    //cleanup
  }

  fseek(fp,sizeof(char)*hp->fileheader.dataoffset,SEEK_SET);
  n=fread(data,sizeof(char),hp->bitmapsize, fp);
  if(n<1){
    //cleanup
  }

for(xx = 0; xx < hp->width; xx++)
{
    for(yy = 0; yy < hp->height; yy++)
    {
        avgB = avgG = avgR = 0;
        ile = 0;

        for(x = xx; x < hp->width && x < xx + blurSize; x++)
        {


            for(y = yy; y < hp->height && y < yy + blurSize; y++)
            {
                avgB += data[x*3 + y*hp->width*3 + 0];
                avgG += data[x*3 + y*hp->width*3 + 1];
                avgR += data[x*3 + y*hp->width*3 + 2];
                ile++;
            }
        }

        avgB = avgB / ile;
        avgG = avgG / ile;
        avgR = avgR / ile;

        data[xx*3 + yy*hp->width*3 + 0] = avgB;
        data[xx*3 + yy*hp->width*3 + 1] = avgG;
        data[xx*3 + yy*hp->width*3 + 2] = avgR;
    }
}

    //Open output file:
  out = fopen(output, "wb");
  if(out==NULL){
    //cleanup
  }

  n=fwrite(hp,sizeof(char),sizeof(bitmap_header),out);
  if(n<1){
    //cleanup
  }
  fseek(out,sizeof(char)*hp->fileheader.dataoffset,SEEK_SET);
  n=fwrite(data,sizeof(char),hp->bitmapsize,out);
  if(n<1){
    //cleanup
  }

  fclose(fp);
  fclose(out);
  free(hp);
  free(data);
  return 0;
}