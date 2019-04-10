#include <stdlib.h>
#include <stdio.h>
#include <string.h>

unsigned char* readBMP(char* filename)
{
    int i;
    FILE* f = fopen(filename, "rb");
    printf("eee");
    unsigned char info[54];
    fread(info, sizeof(unsigned char), 54, f); // read the 54-byte header
    printf("eee");

    // extract image height and width from header
    int width = *(int*)&info[18];
    int height = *(int*)&info[22];
    
    printf("%d",width);
    printf("%d",height);

    int size = 3 * width * height;
    unsigned char* data[size]; // allocate 3 bytes per pixel
    fread(data, sizeof(unsigned char), size, f); // read the rest of the data at once
    fclose(f);

    for(i = 0; i < size; i += 3)
    {
            unsigned char tmp = data[i];
            data[i] = data[i+2];
            data[i+2] = tmp;
    }

    return data;
}


int main(void) {

    printf("hola\n");
    readBMP("/home2/users/alumnes/1202092/dades/rio.bmp");
    return 0;

}


