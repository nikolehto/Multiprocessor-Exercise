// zncc.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

void resizeAndGreyScaleImg(std::vector<unsigned char> &img
	, unsigned &width
	, unsigned &height
	, unsigned sampling_step)
{
	std::vector<unsigned char> newImage;

	//const unsigned char r_con = 0.2126 * 255, g_con = 0.7152 * 255, b_con = 0.0722 * 255; // TODO (for performance somehow use char? maybe output should be shifted or something) 
	float r_con = 0.2126, g_con = 0.7152, b_con = 0.0722;

	for (unsigned row = 0; row < height; row += sampling_step)
	{
		for (unsigned column = 0; column < width; column += sampling_step)
		{
			const unsigned index = row * width * 4 + column * 4;

			newImage.push_back(img.at(index) *r_con
				+ img.at(index + 1) * g_con
				+ img.at(index + 2) * b_con);
		}
	}

	height /= sampling_step;
	width /= sampling_step;

	img.swap(newImage); 
}


void calc_zncc(std::vector<unsigned char> &l_img
	, std::vector<unsigned char> &r_img
	, unsigned &img_width
	, unsigned &img_height
	, unsigned &win_width
	, unsigned &win_height
	, unsigned &max_disparity)
{
	// TODO algorithm 

	std::vector<unsigned char> disparity_image; // TODO - pass as parameter

	unsigned current_maximum_sum = 0;
	unsigned best_disparity_value = 0;

	unsigned zncc_value = 0;

	const unsigned win_rad_x = win_width / 2;
	const unsigned win_rad_y = win_height / 2;

	const unsigned start_y = win_rad_y;
	const unsigned start_x = win_rad_x;
	const unsigned stop_y = img_height - win_rad_y;
	const unsigned stop_x = img_width - win_rad_x;

	//unsigned step = 1; 	// todo step parameter for faster testing  - NOTE disparity indexing
	for (unsigned int img_y = start_y; img_y < stop_y; img_y++)
	{
		for (unsigned int img_x = start_x; img_x < stop_x; img_x++)
		{
			// const unsigned base_index = img_y * img_width + img_x;

			for (unsigned int disp_x = 0; disp_x < max_disparity; disp_x++)
			{
				// check that disp_x + img_x <= stop_x
				unsigned char l_mean;
				unsigned char r_mean;

				for (int win_y = -((int)win_rad_y); win_y <= win_rad_y ; win_y++) // TODO check <=
				{
					for (int win_x = -((int)win_rad_x); win_x <= win_rad_x; win_x++)
					{
						// calculate the mean value of each window

						// TODO Why would I calculate mean in here I think I will not calculate it for every single disp_x value? It does not change ? Out from disp-loop ? Pseudo-code says it to be here
						// I guess we should make mean image before zncc
						
						//unsigned w_index
						//l_mean += l_img.at(w_index)

					}
				}
				for (unsigned int win_y = 0; win_y < win_height; win_y++)
				{
					for (unsigned int win_x = 0; win_x < win_width; win_x++)
					{
						// calculate zncc value of each window
						
						// limit checks
					}

				}
				//
				if (zncc_value > current_maximum_sum)
				{
					current_maximum_sum = zncc_value; // TODO : is this correct? 
					best_disparity_value = zncc_value; // TODO : is this correct? 
				}
			}

			//disparity_image.at(<index>) = best_disparity_value 
		}
		
	}
}

bool encodeGreyImg(const std::string &filename, std::vector<unsigned char>& image, unsigned width, unsigned height)
{
	//Encode the image
	unsigned error = lodepng::encode(filename, image, width, height, LodePNGColorType::LCT_GREY);

	//if there's an error, display it
	if (error)
	{
		std::cout << "encoder error " << error << ": " << lodepng_error_text(error) << std::endl;
		return false;
	}
	return true;
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
	std::string grey_l_file;
	std::string grey_r_file;
	unsigned img_width, img_height;
	unsigned win_width, win_height, max_disparity;
	unsigned sampling_step;

	unsigned l_width, l_height, r_width, r_height; // to check that images have same width and height
	bool write_grey_scale_img_to_file;


	// hard coded values - TODO: argument reader and real values
	write_grey_scale_img_to_file = true;
	sampling_step = 4;
	grey_l_file = "output/grey_im0.png";
	grey_r_file = "output/grey_im1.png";
	win_width = 2;
	win_height = 2;
	max_disparity = 2;  // use bigger value, only for early-testing TODO


	// if arguments - try to read such a files
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

	// check that image size match
	if (l_width != r_width || l_height != r_height)
	{
		std::cout << "different sized images, exiting" << std::endl;
		system("pause");
		return 2;
	}

	// resize and grayscale images one by one
	resizeAndGreyScaleImg(l_img, l_width, l_height, sampling_step);
	resizeAndGreyScaleImg(r_img, r_width, r_height, sampling_step);

	// images are same sized - use img_height as common name
	img_height = l_height;
	img_width = l_width;

	if (write_grey_scale_img_to_file)
	{
		encodeGreyImg(grey_l_file, l_img, img_width, img_height);
		encodeGreyImg(grey_r_file, r_img, img_width, img_height);
	}

	/*
	// check that we got something  TODO: remove
	std::cout << (unsigned int)l_img.at(100) << std::endl;
	std::cout << (unsigned int)r_img.at(100) << std::endl;

	*/

	// TODO to implement functionality
	calc_zncc(l_img, r_img, img_width, img_height, win_width, win_height, max_disparity);



	system("pause");
    return 0;
}

