// zncc.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"


// Method is from example_decode.cpp from lodepng examples https://raw.githubusercontent.com/lvandeve/lodepng/master/examples/example_decode.cpp
void decodeOneStep(const char *filename, std::vector<unsigned char> &image)
{
	
	unsigned width, height;

	//decode
	unsigned error = lodepng::decode(image, width, height, filename);

	//if there's an error, display it - else show size of image
	if (error) std::cout << "decoder error " << error << ": " << lodepng_error_text(error) << std::endl;
	else std::cout << "size: " << width << "*" << height << std::endl;
	//the pixels are now in the vector "image", 4 bytes per pixel, ordered RGBARGBA..., use it as texture, draw it, ...
}


int main(int argc, char *argv[])
{
	std::vector<unsigned char> l_img; 
	std::vector<unsigned char> r_img; 
	const char* l_file;
	const char* r_file;

	if (argc == 2)
	{
		l_file = argv[1];
		r_file = argv[2];
	}
	else
	{ 
		l_file = "images/im0.png";
		r_file = "images/im0.png";
	}
	decodeOneStep(l_file, l_img);
	decodeOneStep(r_file, r_img);

    return 0;
}

