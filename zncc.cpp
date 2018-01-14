// zncc.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"


// Based on example_decode.cpp from lodepng examples https://raw.githubusercontent.com/lvandeve/lodepng/master/examples/example_decode.cpp
void decodeOneStep(const char* filename)
{
	std::vector<unsigned char> image; //the raw pixels
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
	const char* filename = argc > 1 ? argv[1] : "images/im0.png";

	decodeOneStep(filename);

    return 0;
}

