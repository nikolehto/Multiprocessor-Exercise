// zncc.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

void calc_zncc(std::vector<unsigned char> &l_img
	, std::vector<unsigned char> &r_img
	, unsigned &img_width
	, unsigned &img_height
	, unsigned &w_width
	, unsigned &w_height)
{

	// TODO
}

// Method is based on example_decode.cpp from lodepng examples https://raw.githubusercontent.com/lvandeve/lodepng/master/examples/example_decode.cpp
bool decodeImg(const std::string &filename, std::vector<unsigned char> &image, unsigned &width, unsigned &height)
{
	unsigned int error = lodepng::decode(image, width, height, filename);
	//if there's an error, display it - else show size of image
	
	if (error)
	{
		std::cout << "decoder error " << error << ": " << lodepng_error_text(error) << std::endl;
		return false;
	}

	return true;
	//the pixels are now in the vector "image", 4 bytes per pixel, ordered RGBARGBA..., use it as texture, draw it, ...
}


int main(int argc, char *argv[])
{
	std::vector<unsigned char> l_img; 
	std::vector<unsigned char> r_img; 
	std::string l_file;
	std::string r_file;
	unsigned img_width, img_height;
	unsigned win_width, win_height;

	unsigned l_width, l_height, r_width, r_height; // to check that images have same width and height

	// hard coded values - TODO: argument reader 
	win_width = 3;
	win_height = 3;

	if (argc == 2)
	{
		l_file = *argv[1];
		r_file = *argv[2];
	}
	else
	{
		l_file = "images/im0.png";
		r_file = "images/im1.png";
	}

	if (!(decodeImg(l_file, l_img, l_width, l_height)
		&& decodeImg(r_file, r_img, r_width, r_height)))
	{
		std::cout << "read failed, exiting" << std::endl;
		system("pause");
		return 1;
	}

	if (l_width != r_width || l_height != r_height)
	{
		std::cout << "different sized images, exiting" << std::endl;
		system("pause");
		return 2;
	}

	// now images are same sized - use img_height variable so on.. 
	img_height = l_height;
	img_width = l_width;

	calc_zncc(l_img, r_img, img_width, img_height, win_width, win_height);

	// check
	std::cout << (unsigned int) l_img.at(100) << std::endl;
	std::cout << (unsigned int) r_img.at(100) << std::endl;

	system("pause");
    return 0;
}

